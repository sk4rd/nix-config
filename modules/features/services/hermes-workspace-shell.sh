# Called through admin's existing sudo access; no sudo rights for hermes.
if [[ $(id -un) != hermes ]]; then
  printf 'Run this helper as the hermes account.\n' >&2
  exit 1
fi
if [[ $# -ne 0 ]]; then
  printf 'This helper accepts no arguments.\n' >&2
  exit 2
fi
export HOME=/srv/hermes/home
export HERMES_HOME="$HOME"
# writeShellApplication's interpreter lacks Readline; PATH starts with bashInteractive.
export SHELL
SHELL="$(command -v bash)"
unset BASH_ENV ENV CDPATH
cd /srv/hermes/workspace
export PS1='[HERMES @ NAS] \w\n\$ '
if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then
  # Tokens are substituted from the shared Neon Flux palette by Nix.
  accent='@accent@'
  structure='@structure@'
  rgb() {
    printf '%d;%d;%d' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"
  }
  cyan="$(rgb "$accent")"
  violet="$(rgb "$structure")"
  printf '\033]0;HERMES · NAS workspace\007'
  printf '\n\033[38;2;%sm  ◆ HERMES · NAS\033[0m\n' "$cyan"
  printf '\033[38;2;%sm  ──────────────────────────────\033[0m\n' "$violet"
  printf -v PS1 '\\[\\e[38;2;%sm\\]HERMES\\[\\e[0m\\] @ NAS \\[\\e[38;2;%sm\\]\\w\\[\\e[0m\\]\\n\\[\\e[38;2;%sm\\]❯\\[\\e[0m\\] ' "$cyan" "$violet" "$cyan"
else
  printf '\n  HERMES · NAS\n'
fi
printf '  Workspace: /srv/hermes/workspace · account: hermes\n  Git is ready. Type exit to disconnect.\n\n'
exec "$SHELL" --noprofile --norc -i
