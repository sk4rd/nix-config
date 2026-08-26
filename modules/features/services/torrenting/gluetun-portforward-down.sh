#!/bin/sh
set -eu

. /scripts/qbittorrent-lib.sh

qbt_wait_api || exit 0
qbt_login || exit 0
qbt_post "$API/app/setPreferences" \
  'json={"listen_port":0,"current_network_interface":"lo"}' || true
