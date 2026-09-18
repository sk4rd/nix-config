#!/bin/sh
# Configure qBittorrent through the API of the process inside the VPN
# container. Runs as a oneshot: a switch restarts docker, and this unit is
# ordered after the container units but can still run while docker is
# recreating the container, which answers "No such container" and fails the
# whole switch.
set -eu

container=qbittorrent-vpn

# Wait for the container instead of failing immediately. Each probe is bounded
# on its own so a docker daemon that accepts the connection and then hangs
# cannot stall the loop, and the loop is bounded in attempts: a container that
# genuinely never appears still fails the unit, because the same command after
# the loop is the real execution and has no fallback.
tries=0
while [ "$tries" -lt 30 ]; do
  if timeout -k 2 5 docker exec "$container" true 2>/dev/null; then
    break
  fi
  tries=$((tries + 1))
  sleep 2
done

docker exec "$container" sh -lc '
  set -e
  . /scripts/qbittorrent-lib.sh
  qbt_wait_api
  qbt_login
  qbt_set_listen_port_from_file
  ensure_category Movies /media/Movies
  ensure_category Shows /media/Shows
'
