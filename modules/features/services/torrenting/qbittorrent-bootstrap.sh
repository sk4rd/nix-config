#!/bin/sh
# Container-unit ordering can still race Docker recreation during a switch.
set -eu

container=qbittorrent-vpn

# Bound each probe against Docker hangs and retries against a missing container.
# The final exec still fails the unit if the container never becomes available.
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
  ensure_category radarr /media/.downloads/radarr
  ensure_category sonarr /media/.downloads/sonarr
'
