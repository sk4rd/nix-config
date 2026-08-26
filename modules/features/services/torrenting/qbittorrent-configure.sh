config_path=/srv/qbittorrent/config/qBittorrent/qBittorrent.conf
install -d -m 0750 -o qbittorrent -g qbittorrent "$(dirname "$config_path")"

python3 - "$config_path" <<'PY'
from configparser import RawConfigParser
import base64
import binascii
import hashlib
import os
from pathlib import Path
import re
import sys

config_path = Path(sys.argv[1])
password_path = Path("/run/secrets/nas/qbittorrent/webui_password")
config = RawConfigParser(interpolation=None, strict=False)
config.optionxform = str
if config_path.exists():
    config.read(config_path)

defaults = {
    "AutoRun": {"enabled": "false", "program": ""},
    "LegalNotice": {"Accepted": "true"},
    "Preferences": {
        "Connection\\UPnP": "false",
        "Downloads\\SavePath": "/downloads/",
        "Downloads\\TempPathEnabled": "true",
        "Downloads\\TempPath": "/downloads/incomplete/",
        "WebUI\\Address": "*",
        "WebUI\\Port": "18080",
        "WebUI\\CSRFProtection": "true",
        "WebUI\\HostHeaderValidation": "true",
        # The local API hop is HTTP; external access still terminates TLS at Traefik.
        "WebUI\\SecureCookie": "false",
        "WebUI\\LocalHostAuth": "true",
        "WebUI\\ReverseProxySupportEnabled": "true",
        "WebUI\\TrustedReverseProxiesList": "127.0.0.1/32",
        "WebUI\\ServerDomains": "*",
    },
    # qBittorrent 5.x persists download paths and TMM under [BitTorrent]
    # Session\*; the legacy [Preferences] Downloads\* keys above remain for
    # compatibility. The listen port is runtime state managed by the Gluetun
    # port-forward callbacks and bootstrap, so it is never pinned here.
    "BitTorrent": {
        "Session\\DefaultSavePath": "/downloads/",
        "Session\\TempPathEnabled": "true",
        "Session\\TempPath": "/downloads/incomplete/",
        "Session\\DisableAutoTMMByDefault": "false",
        "Session\\DisableAutoTMMTriggers\\SavePathChanged": "false",
        "Session\\DisableAutoTMMTriggers\\CategorySavePathChanged": "false",
    },
}

for section, values in defaults.items():
    if not config.has_section(section):
        config.add_section(section)
    for key, value in values.items():
        config.set(section, key, value)

password = password_path.read_bytes().rstrip(b"\n")
if not password:
    raise ValueError("qBittorrent WebUI password must not be empty")
if re.fullmatch(rb"[A-Za-z0-9._~-]+", password) is None:
    raise ValueError("qBittorrent WebUI password must be URL-form-safe")
stored_hash = config.get("Preferences", "WebUI\\Password_PBKDF2", fallback="")
try:
    encoded = stored_hash.strip('"').removeprefix("@ByteArray(").removesuffix(")")
    salt = base64.b64decode(encoded.split(":", 1)[0], validate=True)
    if len(salt) != 16:
        raise ValueError("invalid qBittorrent password salt")
except (binascii.Error, ValueError, IndexError):
    salt = os.urandom(16)

derived_hash = hashlib.pbkdf2_hmac("sha512", password, salt, 100000)
config.set(
    "Preferences",
    "WebUI\\Password_PBKDF2",
    '"@ByteArray({}:{})"'.format(
        base64.b64encode(salt).decode(),
        base64.b64encode(derived_hash).decode(),
    ),
)

with config_path.open("w") as file:
    config.write(file, space_around_delimiters=False)
PY

chmod 0600 "$config_path"
chown qbittorrent:qbittorrent "$config_path"
