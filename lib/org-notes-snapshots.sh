set -euo pipefail
dataset=storage-pool/notes
property=org.nix-config:notes-policy
marker=v1
period=$1
keep=$2
[[ "$keep" =~ ^[1-9][0-9]*$ ]] || exit 2
case "$period" in
  hourly) format=%Y%m%dT%H0000Z ;;
  daily) format=%Y%m%dT000000Z ;;
  monthly) format=%Y%m01T000000Z ;;
  *) exit 2 ;;
esac
exec 9>/run/lock/org-notes-snapshots.lock
flock 9
test "$(findmnt -n -o SOURCE --mountpoint /storage-pool/notes)" = "$dataset"
name="$dataset@org-notes-v1-$period-$(date -u +"$format")"
if ! zfs list -H -t snapshot -o name "$name" >/dev/null 2>&1; then
  zfs snapshot -o "$property=$marker" "$name"
fi
# A name alone is not proof that this policy owns a snapshot.
test "$(zfs get -H -o value "$property" "$name")" = "$marker"
listing=$(zfs list -H -t snapshot -o name -s name -r "$dataset")
managed=()
while IFS= read -r candidate; do
  if [[ "$candidate" =~ ^storage-pool/notes@org-notes-v1-$period-[0-9]{8}T[0-9]{6}Z$ ]] &&
    [[ "$(zfs get -H -o value "$property" "$candidate")" == "$marker" ]]; then
    managed+=("$candidate")
  fi
done <<< "$listing"
for ((i=0; i<${#managed[@]}-keep; i++)); do
  zfs destroy "${managed[i]}"
done
