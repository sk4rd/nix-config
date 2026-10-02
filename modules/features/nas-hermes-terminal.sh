# Optional host override supports a WireGuard route without changing the launcher.
if [[ $# -gt 1 ]]; then
  printf 'Usage: nas-hermes-terminal [NAS-host-or-IP]\n' >&2
  exit 2
fi
host="${1:-${NAS_HERMES_HOST:-192.168.178.3}}"
if [[ ! "$host" =~ ^[a-zA-Z0-9][a-zA-Z0-9.:-]*$ ]]; then
  printf 'Invalid NAS host. Supply a hostname or IP, not a command or SSH option.\n' >&2
  exit 2
fi
exec ssh -a -t -o StrictHostKeyChecking=yes -o ConnectTimeout=10 \
  "admin@$host" 'sudo -n -u hermes /run/current-system/sw/bin/hermes-workspace-shell'
