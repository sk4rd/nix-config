#!/usr/bin/env python3
# Apply Prowlarr's declarative configuration on each start: web authentication
# and the qBittorrent download client. Runs after the Prowlarr container has
# created its config and database, using Prowlarr's own API.
import json
import time
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

config_xml = Path("/srv/prowlarr/config/config.xml")
prowlarr_username = Path("/run/secrets/nas/prowlarr/username").read_text().strip()
prowlarr_password = Path("/run/secrets/nas/prowlarr/password").read_text().strip()
qb_username = "admin"
qb_password = Path("/run/secrets/nas/qbittorrent/webui_password").read_text().strip()
if not prowlarr_password or not qb_password:
    raise SystemExit("prowlarr credentials must not be empty")


def api_key():
    root = ET.parse(config_xml).getroot()
    el = root.find("ApiKey")
    return el.text.strip() if el is not None and el.text else None


def request(method, path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(
        "http://127.0.0.1:9696" + path,
        data=data,
        method=method,
        headers={
            "X-Api-Key": api_key(),
            "Content-Type": "application/json",
        },
    )
    return urllib.request.urlopen(req, timeout=15)


ready = False
for _ in range(60):
    try:
        if api_key():
            request("GET", "/api/v1/system/status")
            ready = True
            break
    except Exception:
        pass
    time.sleep(2)
if not ready:
    raise SystemExit("prowlarr API not ready")

host = json.load(request("GET", "/api/v1/config/host"))
host["authenticationMethod"] = "forms"
host["authenticationRequired"] = "enabled"
host["username"] = prowlarr_username
host["password"] = prowlarr_password
host["passwordConfirmation"] = prowlarr_password
request("PUT", "/api/v1/config/host", host)

client = {
    "enable": True,
    "protocol": "torrent",
    "priority": 1,
    "name": "qBittorrent",
    "implementation": "QBittorrent",
    "configContract": "QBittorrentSettings",
    "categories": [],
    "fields": [
        {"name": "host", "value": "127.0.0.1"},
        {"name": "port", "value": 18080},
        {"name": "useSsl", "value": False},
        {"name": "urlBase", "value": ""},
        {"name": "username", "value": qb_username},
        {"name": "password", "value": qb_password},
        {"name": "category", "value": ""},
    ],
}
existing = json.load(request("GET", "/api/v1/downloadclient"))
match = next((c for c in existing if c.get("name") == "qBittorrent"), None)
if match:
    client["id"] = match["id"]
    request("PUT", "/api/v1/downloadclient/{}".format(match["id"]), client)
else:
    request("POST", "/api/v1/downloadclient", client)

tag_label = "cloudflare"
tags = json.load(request("GET", "/api/v1/tag"))
tag = next((t for t in tags if t.get("label") == tag_label), None)
if tag:
    tag_id = tag["id"]
else:
    tag_id = json.load(request("POST", "/api/v1/tag", {"label": tag_label}))["id"]

proxy = {
    "enable": True,
    "name": "FlareSolverr",
    "implementation": "FlareSolverr",
    "configContract": "FlareSolverrSettings",
    "tags": [tag_id],
    "fields": [
        {"name": "host", "value": "http://127.0.0.1:8191/"},
        {"name": "requestTimeout", "value": 60},
    ],
}
existing_proxy = json.load(request("GET", "/api/v1/indexerproxy"))
proxy_match = next(
    (p for p in existing_proxy if p.get("implementation") == "FlareSolverr"), None
)
if proxy_match:
    proxy["id"] = proxy_match["id"]
    request("PUT", "/api/v1/indexerproxy/{}".format(proxy_match["id"]), proxy)
else:
    request("POST", "/api/v1/indexerproxy", proxy)
