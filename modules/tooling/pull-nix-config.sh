#!/usr/bin/env bash
set -euo pipefail

remote=hermes@192.168.178.3
remote_repo=/var/lib/hermes/workspace/nix-config

fail() {
  printf 'pull-nix-config: %s\n' "$1" >&2
  exit 1
}

for command_name in bash hostname ssh rsync mktemp realpath find mkdir rm rmdir mv chmod; do
  command -v "$command_name" >/dev/null 2>&1 || fail "required command '$command_name' is not installed"
done

host_name=$(hostname -s) || fail "could not determine the local hostname"
[[ "$host_name" != nas ]] || fail "refusing to run on nas; run this from the desktop or laptop"

home=$(realpath -e -- "${HOME:?HOME must be set}") || fail "could not resolve HOME"
[[ "$HOME" == /* && "$home" != / ]] || fail "unsafe HOME; use a normal absolute user home directory"
destination=$home/nix-config
state=$home/.local/state/pull-nix-config
baseline=$state/baseline
for state_path in "$home/.local" "$home/.local/state" "$state" "$baseline" "$state/lock"; do
  [[ ! -L "$state_path" ]] || fail "unsafe symlink in sync state: $state_path"
done
[[ ! -e "$baseline" || -d "$baseline" ]] || fail "invalid sync state baseline: $baseline"
umask 077
mkdir -p -- "$state"
chmod 700 -- "$state"
command -v flock >/dev/null 2>&1 || fail "flock is required to prevent concurrent syncs"
exec 9>"$state/lock"
flock -n 9 || fail "another sync is running; wait for it to finish before retrying"

validate_destination() {
  [[ ! -L "$destination" ]] || fail "destination is a symlink: $destination; move it aside before syncing"
  [[ ! -e "$destination" || -d "$destination" ]] || fail "destination is not a directory: $destination"
  if [[ ! -d "$baseline" && -d "$destination" ]]; then
    [[ -z $(find "$destination" -mindepth 1 -maxdepth 1 -print -quit) ]] || fail "nonempty unmanaged destination: $destination; move it aside, then retry with an absent or empty directory"
  fi
}
validate_destination

# Keep these in step with .gitignore; also protect them if force-tracked on NAS.
filters=(--include='.env.example' --exclude='.git' --exclude='.direnv'
  --exclude='result' --exclude='result-*' --exclude='__pycache__'
  --exclude='*.py[cod]' --exclude='.env' --exclude='.env.*'
  --exclude='/secrets/*.plain.*' --exclude='/secrets/*.decrypted.*'
  --exclude='*.swp' --exclude='*~' --exclude='.DS_Store')

check_local() {
  if [[ -d "$baseline" ]]; then
    local changes
    changes=$(rsync -rclpni --delete "${filters[@]}" "$baseline/" "$destination/") || fail "could not compare local source with last sync"
    while IFS= read -r change; do
      # Protected-only parent directories are local scaffolding, not source additions.
      case "$change" in ''|'*deleting '*'/'|'cannot delete non-empty directory: '*) continue ;; esac
      fail "local source changes in $destination; save them elsewhere and restore the last synced source before retrying ($change)"
    done <<<"$changes"
  fi
}
check_local

file_list=$(mktemp) || fail "could not create a temporary file list"
filtered_list=$(mktemp) || {
  rm -f -- "$file_list"
  fail "could not create a temporary filtered file list"
}
work=
baseline_installed=0
cleanup() {
  rm -f -- "$file_list" "$filtered_list"
  if [[ -n "$work" ]]; then
    if [[ "$baseline_installed" == 0 && -d "$work/old-baseline" ]]; then
      if [[ -e "$baseline" || -L "$baseline" ]] || ! mv -- "$work/old-baseline" "$baseline"; then
        printf 'Old baseline preserved at %s/old-baseline; inspect sync state before retrying.\n' "$work" >&2
        return
      fi
    fi
    rm -rf -- "$work"
  fi
}
trap cleanup EXIT

printf 'Listing source files on %s...\n' "$remote" >&2
if ! ssh -T -o StrictHostKeyChecking=yes "$remote" "git -C $remote_repo ls-files --cached --others --exclude-standard --deduplicate -z" >"$file_list"; then
  fail "SSH file listing failed; check SSH authentication and confirm remote git is installed"
fi

while IFS= read -r -d '' path; do
  case "/$path/" in
    */.git/*|*/.direnv/*|*/result/|*/result/*|*/result-*/|*/result-*/*) continue ;;
  esac

  base_name=${path##*/}
  case "$base_name" in
    .env) continue ;;
    .env.*)
      [[ "$base_name" == .env.example ]] || continue
      ;;
  esac

  case "$path" in
    secrets/*.plain.*|secrets/*.decrypted.*) continue ;;
  esac

  printf '%s\0' "$path" >>"$filtered_list"
done <"$file_list"

work=$(mktemp -d "$state/.sync-XXXXXXXXXX")
mkdir -- "$work/incoming"
printf 'Copying source files from %s...\n' "$remote" >&2
if ! rsync --dirs --links --times --perms --relative --from0 \
  --files-from="$filtered_list" --ignore-missing-args --safe-links "${filters[@]}" \
  -e 'ssh -o StrictHostKeyChecking=yes' "$remote:$remote_repo/" "$work/incoming/"; then
  fail "rsync transfer failed; check SSH authentication and confirm remote rsync is installed"
fi

validate_destination
check_local
apply_managed() {
  mkdir -p -- "$destination" || return 1
  if [[ -d "$baseline" ]]; then
    find "$baseline" -mindepth 1 -depth -print0 >"$work/old-paths" || return 1
    while IFS= read -r -d '' old_path; do
      path=${old_path#"$baseline/"}
      incoming=$work/incoming/$path
      if [[ ! -e "$incoming" && ! -L "$incoming" ]]; then
        if [[ -d "$old_path" && ! -L "$old_path" ]]; then
          rmdir -- "$destination/$path" 2>/dev/null || :
        else
          rm -- "$destination/$path" || return 1
        fi
      fi
    done <"$work/old-paths"
  fi
  rsync -rclpt --safe-links "${filters[@]}" "$work/incoming/" "$destination/" >&2
}
if ! apply_managed; then
  if [[ -d "$baseline" ]]; then
    rsync -rclpt --safe-links "${filters[@]}" "$baseline/" "$destination/" >&2 || printf 'Rollback incomplete; preserve local files and inspect %s before retrying.\n' "$destination" >&2
  fi
  fail "apply failed; old baseline retained, managed restoration attempted; inspect $destination before retrying"
fi
if [[ -d "$baseline" ]]; then
  mv -- "$baseline" "$work/old-baseline" || fail "could not preserve old baseline"
fi
if ! mv -- "$work/incoming" "$baseline"; then
  if [[ -d "$work/old-baseline" ]]; then
    mv -- "$work/old-baseline" "$baseline" || fail "baseline recovery failed; old baseline retained at $work/old-baseline"
  fi
  fail "could not install new baseline; inspect $destination before retrying"
fi
baseline_installed=1
printf '%s\n' "$destination"
