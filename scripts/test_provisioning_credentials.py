"""Provisioning scripts read only fixture credential files; no live API or secrets."""

import base64
from configparser import RawConfigParser
import hashlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


class QbittorrentCredentialsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.password = self.root / "custom password"
        self.password.write_bytes(b"fixture-QB_password\n")
        self.config = self.root / "qBittorrent.conf"
        source = ROOT / "modules/features/services/torrenting/qbittorrent-configure.sh"
        self.code = compile(source.read_text().split("<<'PY'\n", 1)[1].split("\nPY\n", 1)[0], str(source), "exec")

    def configure(self, environment):
        read_bytes = Path.read_bytes

        def fixture_bytes(path):
            self.assertTrue(path.is_relative_to(self.root), "credential read escaped the fixture")
            return read_bytes(path)

        with mock.patch.dict(os.environ, environment, clear=True), \
                mock.patch.object(sys, "argv", ["configure", str(self.config)]), \
                mock.patch.object(Path, "read_bytes", fixture_bytes):
            exec(self.code, {})

    def test_nondefault_password_file_and_idempotent_hash(self):
        environment = {"QBITTORRENT_PASSWORD_FILE": str(self.password)}
        self.configure(environment)
        config = RawConfigParser()
        config.read(self.config)
        encoded = config.get("Preferences", "WebUI\\Password_PBKDF2").strip('"').removeprefix("@ByteArray(").removesuffix(")")
        salt, stored = (base64.b64decode(part) for part in encoded.split(":"))
        self.assertEqual(stored, hashlib.pbkdf2_hmac("sha512", b"fixture-QB_password", salt, 100000))
        before = self.config.read_bytes()
        self.configure(environment)
        self.assertEqual(self.config.read_bytes(), before)

    def test_rejects_missing_empty_and_unsafe_credentials(self):
        for case, error in [("environment", KeyError), ("missing", FileNotFoundError),
                            ("empty", ValueError), ("unsafe", ValueError)]:
            with self.subTest(case=case):
                environment = {"QBITTORRENT_PASSWORD_FILE": str(self.password)}
                if case == "environment":
                    environment.clear()
                elif case == "missing":
                    environment["QBITTORRENT_PASSWORD_FILE"] = str(self.root / "missing")
                else:
                    self.password.write_bytes(b"\n" if case == "empty" else b"not safe&\n")
                with self.assertRaises(error):
                    self.configure(environment)
                self.assertFalse(self.config.exists())


class ProwlarrCredentialsTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.values = {
            "PROWLARR_USERNAME_FILE": "fixture-user",
            "PROWLARR_PASSWORD_FILE": "fixture-prowlarr-password",
            "QBITTORRENT_PASSWORD_FILE": "fixture-QB-password",
        }
        self.files = {name: self.root / f"custom {name}" for name in self.values}
        for name, path in self.files.items():
            path.write_text(self.values[name] + "\n")
        self.environment = {name: str(path) for name, path in self.files.items()}
        source = ROOT / "modules/features/services/prowlarr/prowlarr-configure.py"
        self.code = compile(source.read_text(), str(source), "exec")

    def configure(self, environment):
        read_text = Path.read_text
        self.requests = []

        def fixture_text(path):
            self.assertTrue(path.is_relative_to(self.root), "credential read escaped the fixture")
            return read_text(path)

        def response(request, **kwargs):
            self.requests.append(request)
            if request.get_method() == "GET" and request.full_url.endswith(("downloadclient", "tag", "indexerproxy")):
                payload = []
            elif request.full_url.endswith("/tag"):
                payload = {"id": 1}
            else:
                payload = {}
            return io.BytesIO(json.dumps(payload).encode())

        xml = ET.ElementTree(ET.fromstring("<Config><ApiKey>fixture-api-key</ApiKey></Config>"))
        with mock.patch.dict(os.environ, environment, clear=True), \
                mock.patch.object(Path, "read_text", fixture_text), \
                mock.patch.object(ET, "parse", return_value=xml), \
                mock.patch("urllib.request.urlopen", side_effect=response):
            exec(self.code, {})

    def test_nondefault_files_configure_authenticated_api(self):
        self.configure(self.environment)
        host = next(json.loads(r.data) for r in self.requests
                    if r.get_method() == "PUT" and r.full_url.endswith("/config/host"))
        self.assertEqual(host["username"], self.values["PROWLARR_USERNAME_FILE"])
        self.assertEqual(host["password"], self.values["PROWLARR_PASSWORD_FILE"])
        self.assertEqual(host["authenticationMethod"], "forms")
        self.assertEqual(host["authenticationRequired"], "enabled")
        client = next(json.loads(r.data) for r in self.requests
                      if r.get_method() == "POST" and r.full_url.endswith("/downloadclient"))
        fields = {f["name"]: f["value"] for f in client["fields"]}
        self.assertEqual(fields["username"], "admin")
        self.assertEqual(fields["password"], self.values["QBITTORRENT_PASSWORD_FILE"])
        for request in self.requests:
            self.assertEqual(request.get_header("X-api-key"), "fixture-api-key")

    def test_rejects_missing_and_empty_credentials_before_api_calls(self):
        for name, value in self.values.items():
            for case, error in [("environment", KeyError), ("missing", FileNotFoundError),
                                ("empty", SystemExit)]:
                with self.subTest(name=name, case=case):
                    environment = self.environment.copy()
                    if case == "environment":
                        del environment[name]
                    elif case == "missing":
                        environment[name] = str(self.root / "missing")
                    else:
                        self.files[name].write_text("\n")
                    with self.assertRaises(error) as failure:
                        self.configure(environment)
                    self.assertEqual(self.requests, [])
                    self.assertNotIn(value, str(failure.exception))
                    self.files[name].write_text(value + "\n")


if __name__ == "__main__":
    unittest.main()
