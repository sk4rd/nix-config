"""Regression checks for evaluated configuration scope; no builds or deployment."""

import json
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
HOME_SUMMARY = r'''
lib: h: {
  lf = h.programs.lf.enable;
  lazygit = h.programs.lazygit.enable;
  gitReviewLauncher = builtins.hasAttr "nix-config-review" h.xdg.desktopEntries;
  packages = map lib.getName h.home.packages;
  vscodeTasks = h.programs.vscode.profiles.default.userTasks or {};
}
'''
HOME_QUERY = 'hs: builtins.mapAttrs (_: h: (' + HOME_SUMMARY + ') h.pkgs.lib h.config) hs'
QUERY = r'''
cs: let
  lib = cs.laptop.pkgs.lib;
  summarizeHome = (''' + HOME_SUMMARY + r''') lib;
  summarize = n: let c = n.config; in {
    hostname = c.networking.hostName;
    openrgb = c.services.hardware.openrgb.enable;
    libvirt = c.virtualisation.libvirtd.enable;
    kernelModules = c.boot.kernelModules;
    localsendTCP = builtins.elem 53317 c.networking.firewall.allowedTCPPorts;
    localsendUDP = builtins.elem 53317 c.networking.firewall.allowedUDPPorts;
    users = builtins.mapAttrs (_: u: u.openssh.authorizedKeys.keys) c.users.users;
    vpnConsumers = builtins.listToAttrs (map (name: let
      unit = c.systemd.services.${name} or {};
    in {
      inherit name;
      value = {
        after = unit.after or [];
        requires = unit.requires or [];
        bindsTo = unit.bindsTo or [];
        partOf = unit.partOf or [];
      };
    }) [ "docker-qbittorrent" "docker-firefox" "docker-prowlarr" "docker-flaresolverr" ]);
    searxng = {
      settings = builtins.hasAttr "searxng.settings.yml" c.sops.templates;
      legacyEnvironment = builtins.hasAttr "searxng.env" c.sops.templates;
      environmentFiles = c.virtualisation.oci-containers.containers.searxng.environmentFiles or [];
    };
    homes = builtins.mapAttrs (_: summarizeHome) (c.home-manager.users or {});
  };
in builtins.mapAttrs (_: summarize) cs
'''


class ConfigurationCleanupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = subprocess.run(
            ["nix", "eval", "--json", "--no-write-lock-file",
             "--option", "eval-cache", "false",
             ".#nixosConfigurations", "--apply", QUERY],
            cwd=ROOT, text=True, capture_output=True, check=True, timeout=180,
        )
        cls.hosts = json.loads(result.stdout)
        result = subprocess.run(
            ["nix", "eval", "--json", "--no-write-lock-file",
             "--option", "eval-cache", "false",
             ".#homeConfigurations", "--apply", HOME_QUERY],
            cwd=ROOT, text=True, capture_output=True, check=True, timeout=180,
        )
        cls.homes = json.loads(result.stdout)

    def test_hostnames_match_flake_configuration_names(self):
        for name, host in self.hosts.items():
            with self.subTest(host=name):
                self.assertEqual(host["hostname"], name)

    def test_standalone_development_homes(self):
        self.assertIn("miko", self.homes)
        for name, home in self.homes.items():
            with self.subTest(home=name):
                self.assertFalse(home["lf"])
                self.assertIn("yazi", home["packages"])
                self.assertTrue(home["lazygit"])
                self.assertFalse(home["gitReviewLauncher"])
                self.assertNotIn("review-nix-config", home["packages"])

    def test_localsend_firewall_only_on_workstations(self):
        for name, host in self.hosts.items():
            with self.subTest(host=name):
                expected = name in {"desktop", "laptop"}
                self.assertEqual(host["localsendTCP"], expected)
                self.assertEqual(host["localsendUDP"], expected)

    def test_unused_openrgb_removed(self):
        for name, host in self.hosts.items():
            with self.subTest(host=name):
                self.assertFalse(host["openrgb"])

    def test_libvirt_preserved_only_on_workstations(self):
        for name, host in self.hosts.items():
            with self.subTest(host=name):
                self.assertEqual(host["libvirt"], name in {"desktop", "laptop"})

    def test_nas_does_not_force_kvm(self):
        self.assertNotIn("kvm-intel", self.hosts["nas"]["kernelModules"])

    def test_yazi_retained_and_lf_removed(self):
        for name, host in self.hosts.items():
            for user, home in host["homes"].items():
                with self.subTest(host=name, user=user):
                    self.assertFalse(home["lf"])
                    self.assertIn("yazi", home["packages"])

    def test_operator_key_scope_unchanged(self):
        key = (ROOT / "modules/users/miko/ssh.pub").read_text().rstrip("\n")
        expected = {"desktop": "miko", "laptop": "miko", "nas": "admin"}
        for name, host in self.hosts.items():
            for user, keys in host["users"].items():
                with self.subTest(host=name, user=user):
                    self.assertEqual(key in keys, expected.get(name) == user)

    def test_lazygit_available_without_review_wrapper(self):
        self.assertEqual(self.hosts["nas"]["homes"], {})
        for name in ("desktop", "laptop", "wsl"):
            with self.subTest(host=name):
                home = self.hosts[name]["homes"]["miko"]
                self.assertTrue(home["lazygit"])
                self.assertFalse(home["gitReviewLauncher"])
                self.assertNotIn("review-nix-config", home["packages"])

    def test_all_vpn_namespace_consumers_restart_with_owner(self):
        owner = "docker-qbittorrent-vpn.service"
        for name, unit in self.hosts["nas"]["vpnConsumers"].items():
            with self.subTest(service=name):
                self.assertIn(owner, unit["bindsTo"])
                self.assertIn(owner, unit["partOf"])
                self.assertEqual(unit["after"].count(owner), 1)
                self.assertEqual(unit["requires"].count(owner), 1)

    def test_searxng_uses_only_settings_secret_channel(self):
        settings = self.hosts["nas"]["searxng"]
        self.assertTrue(settings["settings"])
        self.assertFalse(settings["legacyEnvironment"])
        self.assertEqual(settings["environmentFiles"], [])

    def test_vscode_tasks_share_matchers_without_changing_commands(self):
        source = json.loads((ROOT / "modules/features/vscode/tasks.json").read_text())
        self.assertEqual(len(source["problemMatcher"]), 3)
        self.assertEqual(
            [task["args"] for task in source["tasks"]],
            [["build"], ["test"], ["test", "--", "--nocapture"],
             ["clippy", "--all-targets"], ["run"]],
        )
        self.assertTrue(all("problemMatcher" not in task for task in source["tasks"]))
        expected = {
            "version": source["version"],
            "tasks": [dict(task, problemMatcher=source["problemMatcher"])
                      for task in source["tasks"]],
        }
        for name in ("desktop", "laptop"):
            with self.subTest(host=name):
                actual = self.hosts[name]["homes"]["miko"]["vscodeTasks"]
                self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
