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
if [[ -d nix-config/.git ]]; then
  cd nix-config
fi
printf 'NAS Hermes workspace — account: hermes. Git is available; exit returns to your laptop.\n'
exec "$SHELL" --noprofile --norc -i
