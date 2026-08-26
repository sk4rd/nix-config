#!/bin/sh
set -eu

. /scripts/qbittorrent-lib.sh

qbt_wait_api
qbt_login
qbt_set_listen_port "$1" "$2"
