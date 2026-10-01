#!/usr/bin/env python3
"""NAS helper contracts, optional snapshot parity and safe fake-installer checks."""
import argparse
import copy
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "lib/nas-service-helpers.nix"
OPTIONS = argparse.Namespace(before=None, after=None, installer=None)


def evaluate(expression, *, succeeds=True):
    result = subprocess.run(
        ["nix", "eval", "--impure", "--json", "--expr", f"let h = import {HELPER}; in {expression}"],
        text=True, capture_output=True, check=False,
    )
    if not succeeds:
        return result.returncode != 0
    if result.returncode:
        raise AssertionError(result.stderr)
    return json.loads(result.stdout)


class HelperContracts(unittest.TestCase):
    def test_mounts_are_explicit_and_ordered(self):
        for mounts in (["/srv/a"], ["/srv/a", "/srv/media", "/srv/downloads"]):
            nix_mounts = "[ " + " ".join(json.dumps(m) for m in mounts) + " ]"
            self.assertEqual(evaluate(f"h.mountSafety {nix_mounts}"), {
                "after": ["zfs-mount.service"], "requires": ["zfs-mount.service"],
                "unitConfig": {"RequiresMountsFor": mounts, "AssertPathIsMountPoint": mounts},
            })

    def test_route_public_and_trusted(self):
        for exposure in ("public", "trustedNetworks"):
            value = evaluate('h.httpsRoute { router = "dashboard"; backend = "homepage"; '
                             'domain = "dashboard.example"; url = "http://127.0.0.1:3000"; '
                             f'exposure = "{exposure}"; }}')
            router = {"rule": "Host(`dashboard.example`)", "entryPoints": ["websecure"],
                      "service": "homepage", "tls": {"certResolver": "cloudflare"}}
            if exposure == "trustedNetworks":
                router["middlewares"] = ["trustedNetworks"]
            self.assertEqual(value, {"routers": {"dashboard": router}, "services": {
                "homepage": {"loadBalancer": {"servers": [{"url": "http://127.0.0.1:3000"}]}}}})

    def test_qbittorrent_host_header(self):
        value = evaluate('h.httpsRoute { router = "qbittorrent"; backend = "qbittorrent"; '
                         'domain = "torrent.example"; url = "http://127.0.0.1:18080"; '
                         'exposure = "trustedNetworks"; passHostHeader = false; }')
        self.assertIs(value["services"]["qbittorrent"]["loadBalancer"]["passHostHeader"], False)

    def test_exposure_cannot_be_omitted_or_misspelled(self):
        args = '{ router = "r"; backend = "s"; domain = "example"; url = "http://localhost"; '
        self.assertTrue(evaluate("h.httpsRoute " + args + "}", succeeds=False))
        self.assertTrue(evaluate("h.httpsRoute " + args + 'exposure = "trusted"; }', succeeds=False))


def assert_parity(before, after):
    """Allow only Homepage's explicitly requested lifecycle delta."""
    for key in ("routes", "ddclient", "secrets", "templates"):
        assert before[key] == after[key], f"{key} changed"
    expected = copy.deepcopy(before["units"])
    removed = expected.pop("homepage-config")
    homepage = expected["docker-homepage"]
    installer = re.search(r"^ExecStart=(.*)$", removed["text"], re.MULTILINE).group(1)
    homepage["after"] = ["sops-install-secrets.service" if x == "homepage-config.service" else x
                         for x in homepage["after"]]
    homepage["requires"].remove("homepage-config.service")
    homepage["text"] = homepage["text"].replace("homepage-config.service", "sops-install-secrets.service", 1)
    homepage["text"] = homepage["text"].replace("Requires=zfs-mount.service homepage-config.service",
                                              "Requires=zfs-mount.service")
    homepage["text"] = re.sub(r"(^ExecStartPre=.*$)", r"\1\nExecStartPre=" + installer,
                              homepage["text"], count=1, flags=re.MULTILINE)
    assert expected == after["units"], "units changed beyond the Homepage delta"


class ArtifactContracts(unittest.TestCase):
    def test_generated_parity(self):
        if not OPTIONS.before:
            self.skipTest("supply --before and --after snapshots")
        before = json.loads(Path(OPTIONS.before).read_text())
        after = json.loads(Path(OPTIONS.after).read_text())
        assert_parity(before, after)
        # Prove parity rejects changes outside the deliberate delta.
        for key in ("routes", "ddclient", "secrets", "templates", "units"):
            mutated = copy.deepcopy(after)
            mutated[key]["unexpected"] = True
            with self.assertRaises(AssertionError):
                assert_parity(before, mutated)

    def test_homepage_installer_with_fake_tools(self):
        if not OPTIONS.installer:
            self.skipTest("supply --installer built writeShellApplication script")
        original = Path(OPTIONS.installer).read_text()
        with tempfile.TemporaryDirectory(prefix="nas-homepage-") as directory:
            root = Path(directory)
            target = root / "homepage"
            target.mkdir()
            fixture = root / "fake-services.yaml"
            log = root / "calls.jsonl"
            fake = root / "bin"
            fake.mkdir()
            # Only substitute coreutils' runtime directory. The built shell wrapper,
            # script body and store settings YAML remain unchanged.
            wrapper = original
            coreutils = re.search(r"/nix/store/[a-z0-9]+-coreutils-[^:\"\n]+/bin", wrapper).group(0)
            real_install = str(Path(coreutils) / "install")
            wrapper = wrapper.replace(coreutils, str(fake))
            fake_body = f'''#!{sys.executable}
import json, os, subprocess, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ["FAKE_LOG"], "a") as stream:
    stream.write(json.dumps([Path(sys.argv[0]).name, *args]) + "\\n")
if Path(sys.argv[0]).name == "chown":
    sys.exit(0)
args = [str(Path(os.environ["FAKE_TARGET"]) / x.removeprefix("/srv/homepage/"))
        if x.startswith("/srv/homepage/") else x for x in args]
args = [os.environ["FAKE_SOURCE"] if x == "/run/secrets/rendered/homepage-services.yaml" else x for x in args]
sys.exit(subprocess.run([{real_install!r}, *args], check=False).returncode)
'''
            for name in ("install", "chown"):
                tool = fake / name
                tool.write_text(fake_body)
                tool.chmod(0o755)
            script = root / "installer"
            script.write_text(wrapper)
            script.chmod(0o755)
            env = {"PATH": str(Path(shutil.which("bash")).parent), "FAKE_LOG": str(log),
                   "FAKE_TARGET": str(target), "FAKE_SOURCE": str(fixture)}
            for content in ("test-only: first\n", "test-only: refreshed\n"):
                fixture.write_text(content)
                result = subprocess.run([str(script)], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((target / "services.yaml").read_text(), content)
                for name in ("settings.yaml", "services.yaml"):
                    self.assertEqual((target / name).stat().st_mode & 0o777, 0o600)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertEqual([call[0] for call in calls], ["install", "install", "chown"] * 2)
            self.assertEqual(calls[2], ["chown", "-R", "1000:1000", "/srv/homepage"])
            self.assertEqual(calls[1][1:3], ["-m", "0600"])
            # Failure must stop before chown or a successful container start.
            fixture.unlink()
            log.unlink()
            result = subprocess.run([str(script)], env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual([json.loads(line)[0] for line in log.read_text().splitlines()],
                             ["install", "install"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before")
    parser.add_argument("--after")
    parser.add_argument("--installer")
    OPTIONS, remaining = parser.parse_known_args()
    if bool(OPTIONS.before) != bool(OPTIONS.after):
        parser.error("--before and --after must be supplied together")
    unittest.main(argv=[sys.argv[0], *remaining])
