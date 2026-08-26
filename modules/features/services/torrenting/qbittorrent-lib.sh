# Shared qBittorrent WebUI API helpers. Sourced by the Gluetun port-forward
# callbacks and the bootstrap service; runs inside the gluetun container.
set -eu

API="http://127.0.0.1:18080/api/v2"
COOKIES=/tmp/qb-cookies.txt
PORT_FILE=/gluetun/forwarded_port

qbt_wait_api() {
  tries=0
  while [ "$tries" -lt 60 ]; do
    if wget -qSO/dev/null "$API/app/webapiVersion" 2>&1 | grep -q "HTTP/"; then
      return 0
    fi
    tries=$((tries + 1))
    sleep 2
  done
  return 1
}

qbt_login() {
  password=$(cat /run/secrets/qbittorrent-webui-password)
  response=$(wget -qO- \
    --save-cookies "$COOKIES" \
    --keep-session-cookies \
    --post-data "username=admin&password=$password" \
    "$API/auth/login")
  [ "$response" = "Ok." ]
}

qbt_post() {
  wget -qO/dev/null --load-cookies "$COOKIES" --post-data "$2" "$1"
}

qbt_get() {
  wget -qO- --load-cookies "$COOKIES" "$1"
}

qbt_set_listen_port() {
  qbt_post "$API/app/setPreferences" \
    "json={\"listen_port\":$1,\"current_network_interface\":\"$2\",\"random_port\":false,\"upnp\":false}"
}

qbt_set_listen_port_from_file() {
  [ -s "$PORT_FILE" ] || return 1
  qbt_set_listen_port "$(cat "$PORT_FILE")" tun0
}

ensure_category() {
  cat="$1"
  save_path="$2"
  if qbt_get "$API/torrents/categories" | grep -Fq "\"$cat\":{\"name\":\"$cat\",\"savePath\":\"$save_path\"}"; then
    return 0
  fi
  qbt_post "$API/torrents/createCategory" "category=$cat&savePath=$save_path" || true
  qbt_post "$API/torrents/editCategory" "category=$cat&savePath=$save_path"
}
