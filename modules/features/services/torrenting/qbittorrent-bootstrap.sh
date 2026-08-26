#!/bin/sh
set -eu

docker exec qbittorrent-vpn sh -lc '
  set -e
  . /scripts/qbittorrent-lib.sh
  qbt_wait_api
  qbt_login
  qbt_set_listen_port_from_file
  ensure_category Movies /media/Movies
  ensure_category Shows /media/Shows
'
