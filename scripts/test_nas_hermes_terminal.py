"""Launcher argument and SSH failures; no network or deployment."""
import json
import os
import pty
import re
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
LAUNCHER = ROOT / "modules/features/nas-hermes-terminal.sh"


class NasHermesTerminalTests(unittest.TestCase):
    def invoke(self, args=(), host=None, ssh_exit=0):
        with tempfile.TemporaryDirectory() as tmp:
            fake = Path(tmp) / "ssh"
            fake.write_text('#!/usr/bin/env python3\nimport json,sys\nprint(json.dumps(sys.argv[1:]))\nsys.exit(' + str(ssh_exit) + ')\n')
            fake.chmod(0o755)
            env = dict(os.environ, PATH=tmp + os.pathsep + os.environ["PATH"])
            env.pop("NAS_HERMES_HOST", None)
            if host is not None:
                env["NAS_HERMES_HOST"] = host
            return subprocess.run(["bash", "-euo", "pipefail", str(LAUNCHER), *args], env=env, text=True, capture_output=True)

    def test_default_route_account_and_strict_host_verification(self):
        r = self.invoke()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(json.loads(r.stdout), ["-a", "-t", "-o", "StrictHostKeyChecking=yes", "-o", "ConnectTimeout=10", "admin@192.168.178.3", "sudo -n -u hermes /run/current-system/sw/bin/hermes-workspace-shell"])

    def test_vpn_override_and_explicit_host_precedence(self):
        self.assertIn("admin@10.0.0.1", json.loads(self.invoke(host="10.0.0.1").stdout))
        self.assertIn("admin@nas.lan", json.loads(self.invoke(args=["nas.lan"], host="10.0.0.1").stdout))

    def test_rejects_injection_and_extra_arguments(self):
        for args in (["-oProxyCommand=evil"], ["nas;evil"], ["admin@nas"], ["nas", "extra"], ["nas host"]):
            with self.subTest(args=args):
                r = self.invoke(args=args)
                self.assertEqual(r.returncode, 2)
                self.assertEqual(r.stdout, "")

    def test_ssh_failure_is_not_hidden(self):
        self.assertEqual(self.invoke(ssh_exit=255).returncode, 255)


class WorkspaceShellTests(unittest.TestCase):
    def test_always_starts_in_workspace_with_hermes_prompt(self):
        source = (ROOT / "modules/features/services/hermes-workspace-shell.sh").read_text()
        for checkout in (False, True):
            with self.subTest(checkout=checkout), tempfile.TemporaryDirectory() as tmp:
                # Reproduce replacement collisions regardless of the system's TMPDIR.
                base = Path(tmp) / "srv/hermes/home"
                workspace = base / "workspace"
                workspace.mkdir(parents=True)
                if checkout:
                    (workspace / "nix-config/.git").mkdir(parents=True)
                fake = base / "id"
                fake.write_text("#!/bin/sh\nprintf 'hermes\\n'\n")
                fake.chmod(0o755)
                script = base / "helper.sh"
                paths = {
                    "/srv/hermes/workspace": str(workspace),
                    "/srv/hermes/home": str(base / "home"),
                }
                script.write_text(re.sub(
                    r"/srv/hermes/(?:workspace|home)",
                    lambda match: paths[match.group()], source,
                ))
                env = dict(os.environ, PATH=str(base) + os.pathsep + os.environ["PATH"])
                r = subprocess.run(["bash", "-euo", "pipefail", str(script)], env=env, input="pwd; printf 'HOME=%s\\n' \"$HOME\"; printf 'PROMPT=%s\\n' \"$PS1\"; exit\n", text=True, capture_output=True)
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertIn(str(workspace), r.stdout)
                self.assertNotIn(str(workspace / "nix-config"), r.stdout)
                self.assertIn("HERMES", r.stdout)
                self.assertIn("PROMPT=", r.stdout)
                self.assertIn("HOME=" + str(base / "home"), r.stdout)

    def test_coloured_terminal_has_palette_title_and_persistent_prompt(self):
        source = (ROOT / "modules/features/services/hermes-workspace-shell.sh").read_text()
        palette = json.loads((ROOT / "modules/features/desktop/neon-flux-theme/palette.json").read_text())
        source = source.replace("@accent@", palette["accent"]).replace("@structure@", palette["structure"])
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            workspace = base / "workspace"
            (workspace / "nix-config").mkdir(parents=True)
            fake = base / "id"
            fake.write_text("#!/bin/sh\nprintf 'hermes\\n'\n")
            fake.chmod(0o755)
            script = base / "helper.sh"
            script.write_text(source.replace("/srv/hermes/workspace", str(workspace)))
            env = dict(os.environ, PATH=tmp + os.pathsep + os.environ["PATH"], TERM="xterm-256color")
            master, slave = pty.openpty()
            try:
                r = subprocess.run(["bash", "-euo", "pipefail", str(script)], env=env,
                                   input="pwd\ncd nix-config\npwd\nexit\n", text=True,
                                   stdout=slave, stderr=slave, timeout=10)
                os.close(slave)
                slave = None
                chunks = []
                while True:
                    try:
                        chunk = os.read(master, 4096)
                    except OSError:
                        break
                    if not chunk:
                        break
                    chunks.append(chunk)
                output = b"".join(chunks).decode()
            finally:
                os.close(master)
                if slave is not None:
                    os.close(slave)
            self.assertEqual(r.returncode, 0, output)
            self.assertIn("\033]0;HERMES · NAS workspace\007", output)
            for name in ("accent", "structure"):
                colour = palette[name].lstrip("#")
                rgb = ";".join(str(int(colour[i:i + 2], 16)) for i in (0, 2, 4))
                self.assertIn("\033[38;2;" + rgb + "m", output)
            self.assertGreaterEqual(output.count("HERMES"), 3)
            self.assertIn(str(workspace / "nix-config"), output)

    def test_launchers_are_scoped_to_intended_hosts(self):
        from scripts.test_feature_composition import evaluate
        result = evaluate(f'''let
          f = builtins.getFlake "{ROOT}";
          names = ps: builtins.map (p: p.name or "") ps;
          inspect = c: {{
            helper = builtins.elem "hermes-workspace-shell" (names c.environment.systemPackages);
            launcher = c.home-manager.users.miko.xdg.desktopEntries ? nas-hermes-terminal;
          }};
        in {{
          desktop = inspect f.nixosConfigurations.desktop.config;
          laptop = inspect f.nixosConfigurations.laptop.config;
          wsl = inspect f.nixosConfigurations.wsl.config;
          nasHelper = builtins.elem "hermes-workspace-shell" (names f.nixosConfigurations.nas.config.environment.systemPackages);
          standaloneLauncher = f.homeConfigurations.miko.config.xdg.desktopEntries ? nas-hermes-terminal;
        }}''')
        self.assertEqual(result["desktop"], {"helper": False, "launcher": True})
        self.assertEqual(result["laptop"], {"helper": False, "launcher": True})
        self.assertEqual(result["wsl"], {"helper": False, "launcher": False})
        self.assertTrue(result["nasHelper"])
        self.assertFalse(result["standaloneLauncher"])


if __name__ == "__main__":
    unittest.main()
