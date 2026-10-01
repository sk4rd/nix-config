"""Exercise Justfile target discovery without building system closures."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("just"), "just is required (run in nix develop)")
class ToolingTests(unittest.TestCase):
    def run_recipe(self, recipe, fail_discovery=False):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            log = directory / "calls.jsonl"
            nix = directory / "nix"
            nix.write_text('''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ["TOOLING_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")
if "--apply" in args and "builtins.attrNames" in args[-1]:
    if os.environ.get("FAIL_DISCOVERY") == "1":
        sys.exit(42)
    print("new-host sibling" if ".#nixosConfigurations" in args else "new-home")
''')
            nix.chmod(0o755)
            env = dict(os.environ, PATH=f"{directory}:{os.environ['PATH']}",
                       TOOLING_LOG=str(log), FAIL_DISCOVERY=str(int(fail_discovery)))
            result = subprocess.run(["just", "--justfile", str(ROOT / "Justfile"), recipe],
                                    env=env, text=True, capture_output=True, timeout=30)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            return result, calls

    def test_eval_discovers_hosts_and_standalone_homes(self):
        result, calls = self.run_recipe("eval")
        self.assertEqual(result.returncode, 0, result.stderr)
        targets = [arg for call in calls for arg in call if arg.startswith(".#")]
        for target in ("nixosConfigurations.new-host.config.system.build.toplevel.drvPath",
                       "nixosConfigurations.sibling.config.system.build.toplevel.drvPath",
                       "homeConfigurations.new-home.activationPackage.drvPath"):
            self.assertIn(".#" + target, targets)
        self.assertNotIn(".#nixosConfigurations.desktop.config.system.build.toplevel.drvPath", targets)

    def test_secrets_discovers_every_host_without_building_closures(self):
        result, calls = self.run_recipe("secrets")
        self.assertEqual(result.returncode, 0, result.stderr)
        builds = [call for call in calls if call[0] == "build"]
        self.assertEqual(len(builds), 2)
        for host, call in zip(("new-host", "sibling"), builds):
            self.assertIn(f".#nixosConfigurations.{host}.config.system.build.sops-nix-manifest", call)
            self.assertIn("--no-link", call)

    def test_full_discovers_all_closures_and_includes_tests(self):
        # Dry-run preserves dependency order without building any real closure.
        result = subprocess.run(["just", "--justfile", str(ROOT / "Justfile"),
                                 "--dry-run", "full"], text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unittest discover", result.stderr)
        self.assertIn("builtins.attrNames", result.stderr)
        self.assertNotIn("nixosConfigurations.desktop", result.stderr)
        self.assertIn(".config.system.build.toplevel", result.stderr)
        self.assertIn(".activationPackage", result.stderr)

    def test_check_scope_remains_eval_and_secrets_only(self):
        result = subprocess.run(["just", "--justfile", str(ROOT / "Justfile"),
                                 "--dry-run", "check"], text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--no-build", result.stderr)
        self.assertIn("sops-nix-manifest", result.stderr)
        self.assertNotIn("unittest", result.stderr)
        self.assertNotIn("statix", result.stderr)
        self.assertNotIn("toplevel\" --no-link", result.stderr)

    def test_build_host_interface_is_preserved(self):
        result = subprocess.run(["just", "--justfile", str(ROOT / "Justfile"),
                                 "--dry-run", "build", "chosen-host"],
                                text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(".#nixosConfigurations.chosen-host.config.system.build.toplevel", result.stderr)
        self.assertIn("--no-link", result.stderr)

    def test_discovery_failure_is_not_silently_skipped(self):
        for recipe in ("eval", "secrets"):
            with self.subTest(recipe=recipe):
                result, calls = self.run_recipe(recipe, fail_discovery=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(any(call[0] == "build" for call in calls))


class DevShellTests(unittest.TestCase):
    def test_python_is_in_the_development_shell(self):
        result = subprocess.run(
            ["nix", "eval", "--json", "--no-write-lock-file", "--option", "eval-cache", "false",
             ".#devShells.x86_64-linux.default", "--apply",
             "s: map (p: p.pname or p.name) s.nativeBuildInputs"],
            cwd=ROOT, text=True, capture_output=True, check=True, timeout=180,
        )
        self.assertIn("python3", json.loads(result.stdout))


if __name__ == "__main__":
    unittest.main()
