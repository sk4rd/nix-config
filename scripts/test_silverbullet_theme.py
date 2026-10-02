"""SilverBullet theme lifecycle and fixture-only installer checks."""

import json
from pathlib import Path
import re
import shlex
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SilverbulletThemeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        expression = f'''let
          f = builtins.getFlake "{ROOT}";
          c = f.nixosConfigurations.nas.config;
        in {{
          backend = c.systemd.units."docker-silverbullet.service".text;
          theme = (c.systemd.units."silverbullet-theme.service" or {{ text = null; }}).text;
          script = (c.systemd.services.silverbullet-theme or {{}}).script or null;
          wantedBy = (c.systemd.services.silverbullet-theme or {{}}).wantedBy or [];
          scope = builtins.mapAttrs (_: h: h.config.systemd.services ? silverbullet-theme) f.nixosConfigurations;
        }}'''
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", expression],
            cwd=ROOT, text=True, capture_output=True, check=True, timeout=60,
        )
        cls.config = json.loads(result.stdout)

    def test_backend_does_not_require_notes_or_theme(self):
        self.assertNotIn("spaces/notes", self.config["backend"])
        self.assertNotIn("silverbullet-theme", self.config["backend"])
        self.assertIn("AssertPathIsMountPoint=/srv/silverbullet", self.config["backend"])
        self.assertIn("RequiresMountsFor=/srv/silverbullet", self.config["backend"])

    def test_theme_is_unprivileged_mount_guarded_and_nas_only(self):
        unit = self.config["theme"]
        self.assertIsNotNone(unit)
        for line in ("User=silverbullet", "Group=silverbullet", "Type=oneshot",
                     "RemainAfterExit=true", "AssertPathIsMountPoint=/srv/silverbullet",
                     "RequiresMountsFor=/srv/silverbullet"):
            self.assertIn(line, unit)
        self.assertNotIn("docker-silverbullet", unit)
        self.assertEqual(self.config["wantedBy"], ["multi-user.target"])
        self.assertEqual(self.config["scope"], {
            "desktop": False, "laptop": False, "nas": True, "wsl": False,
        })

    def install_theme(self, root):
        asset = root / "fixture theme.md"
        asset.write_text("# fixture theme\n")
        script = self.config["script"]
        sources = re.findall(r"/nix/store/[a-z0-9]{32}-silverbullet-neon-flux\.md", script)
        self.assertEqual(len(sources), 1)
        script = script.replace("space=/srv/silverbullet/space/spaces/notes",
                                "space=" + shlex.quote(str(root / "spaces/notes")))
        script = script.replace(sources[0], shlex.quote(str(asset)))
        return subprocess.run(["bash", "-euo", "pipefail", "-c", script],
                              text=True, capture_output=True)

    def test_absent_space_is_visible_and_not_created(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = self.install_theme(root)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("theme skipped", result.stderr)
            self.assertIn("Space Manager", result.stderr)
            self.assertFalse((root / "spaces").exists())

    def test_existing_space_is_updated_without_touching_other_pages(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            notes = root / "spaces/notes"
            notes.mkdir(parents=True)
            target = notes / "Neon Flux.md"
            target.write_text("old theme\n")
            target.chmod(0o644)
            original = target.stat()
            other = notes / "Notes.md"
            other.write_text("keep this page\n")
            other.chmod(0o640)
            for _ in range(2):
                result = self.install_theme(root)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(target.read_text(), "# fixture theme\n")
                current = target.stat()
                self.assertEqual((current.st_uid, current.st_gid), (original.st_uid, original.st_gid))
                self.assertEqual(stat.S_IMODE(current.st_mode), 0o644)
                self.assertEqual(other.read_text(), "keep this page\n")
                self.assertEqual(stat.S_IMODE(other.stat().st_mode), 0o640)

    def test_failed_write_is_not_hidden(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "spaces/notes/Neon Flux.md"
            target.mkdir(parents=True)
            result = self.install_theme(root)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("theme skipped", result.stderr)
            self.assertEqual(list(target.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
