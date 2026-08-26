#!/usr/bin/env python3
# Apply Prowlarr's declarative web authentication on each start. Runs after the
# Prowlarr container has created its config and database, then sets the auth
# method and upserts the admin user through Prowlarr's own API.
import json
import time
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

config_xml = Path("/srv/prowlarr/config/config.xml")
username = Path("/run/secrets/nas/prowlarr/username").read_text().strip()
password = Path("/run/secrets/nas/prowlarr/password").read_text().strip()
if not password:
    raise SystemExit("prowlarr password must not be empty")


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
host["username"] = username
host["password"] = password
host["passwordConfirmation"] = password
request("PUT", "/api/v1/config/host", host)
