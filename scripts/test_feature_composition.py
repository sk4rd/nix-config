"""Small feature-boundary tests without evaluating full host closures."""

import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


def evaluate(expression):
    result = subprocess.run(
        ["nix", "eval", "--impure", "--json", "--expr", expression],
        cwd=ROOT, text=True, capture_output=True, check=True, timeout=60,
    )
    return json.loads(result.stdout)


class FeatureCompositionTests(unittest.TestCase):
    def test_media_has_no_network_policy_or_transfer_package(self):
        result = evaluate(f'''let
          aspect = (import {ROOT}/modules/features/media.nix).den.aspects.media;
          pkgs = {{ yt-dlp = "yt-dlp"; mpv = "mpv"; ffmpeg = "ffmpeg"; localsend = "localsend"; }};
        in {{
          systemPayload = aspect ? nixos;
          packages = (aspect.homeManager {{ inherit pkgs; }}).home.packages;
        }}''')
        self.assertFalse(result["systemPayload"])
        self.assertEqual(result["packages"], ["yt-dlp", "mpv", "ffmpeg"])

    def test_localsend_owns_package_and_both_ports(self):
        result = evaluate(f'''let
          aspect = (import {ROOT}/modules/features/localsend.nix).den.aspects.localsend;
        in {{
          firewall = aspect.nixos.networking.firewall;
          packages = (aspect.homeManager {{ pkgs.localsend = "localsend"; }}).home.packages;
        }}''')
        self.assertEqual(result["packages"], ["localsend"])
        self.assertEqual(result["firewall"], {
            "allowedTCPPorts": [53317], "allowedUDPPorts": [53317],
        })

    def test_hermes_uses_hosted_default_and_repository_workflow_settings(self):
        result = evaluate(f'''let
          c = (builtins.getFlake "{ROOT}").nixosConfigurations.desktop.config;
          s = c.home-manager.users.miko.services.hermes-agent.settings;
        in {{
          modelProvider = s.model.provider;
          defaultModel = s.model.default;
          apiMode = s.model.api_mode;
          reasoningEffort = s.agent.reasoning_effort;
          workerLimit = s.delegation.max_concurrent_children;
          spawnDepth = s.delegation.max_spawn_depth;
          orchestration = s.delegation.orchestrator_enabled;
          reviewProvider = s.auxiliary.review.provider;
          reviewModel = s.auxiliary.review.model;
          trustedProjects = s.skills.trusted_project_dirs;
          llamaCppEnabled = c.services.llama-cpp.enable;
          llamaCppOssUnit = c.systemd.services ? llama-cpp-oss;
        }}''')
        self.assertEqual(result["modelProvider"], "openai-codex")
        self.assertEqual(result["defaultModel"], "gpt-6-luna")
        self.assertEqual(result["apiMode"], "codex_responses")
        self.assertEqual(result["reasoningEffort"], "medium")
        self.assertEqual(result["workerLimit"], 2)
        self.assertEqual(result["spawnDepth"], 1)
        self.assertFalse(result["orchestration"])
        self.assertEqual(result["reviewProvider"], "openai-codex")
        self.assertEqual(result["reviewModel"], "gpt-6-sol")
        self.assertEqual(
            result["trustedProjects"], ["/home/miko/Documents/nix-config"]
        )
        self.assertFalse(result["llamaCppEnabled"])
        self.assertFalse(result["llamaCppOssUnit"])

    def test_shared_hermes_dashboard_is_authenticated_and_proxy_only(self):
        result = evaluate(f'''let
          c = (builtins.getFlake "{ROOT}").nixosConfigurations.nas.config;
          f = c.networking.firewall;
          unit = c.systemd.units."hermes-dashboard.service".text;
        in {{
          inherit unit;
          firewall = {{
            enable = f.enable;
            trustedInterfaces = f.trustedInterfaces;
            allowedTCPPorts = f.allowedTCPPorts;
            allowedTCPPortRanges = f.allowedTCPPortRanges;
            allInterfaces = builtins.mapAttrs (_: v: {{
              allowedTCPPorts = v.allowedTCPPorts;
              allowedTCPPortRanges = v.allowedTCPPortRanges;
            }}) f.allInterfaces;
            interfaces = builtins.mapAttrs (_: v: {{
              allowedTCPPorts = v.allowedTCPPorts;
              allowedTCPPortRanges = v.allowedTCPPortRanges;
            }}) f.interfaces;
            extraInputRules = f.extraInputRules;
            extraCommands = f.extraCommands;
          }};
          route = c.services.traefik.dynamicConfigOptions.http.routers.hermes;
          trustedNetworks =
            c.services.traefik.dynamicConfigOptions.http.middlewares.trustedNetworks.ipAllowList.sourceRange;
          upstream = c.services.traefik.dynamicConfigOptions.http.services.hermes.loadBalancer.servers;
          hermesUid = c.users.users.hermes.uid;
          hermesLinger = c.users.users.hermes.linger;
          hermesUnit = c.systemd.units."hermes-dashboard.service".text;
        }}''')
        unit = result["unit"]
        self.assertRegex(unit, r"(?m)^WorkingDirectory=/srv/hermes$")
        self.assertRegex(unit, r"(?m)^AssertPathIsMountPoint=/srv/hermes$")
        self.assertRegex(unit, r"(?m)^RequiresMountsFor=/srv/hermes$")
        self.assertNotIn("sops-install-secrets.service", unit)
        self.assertIn(
            "install -d -o hermes -g hermes -m 0750 /srv/hermes/workspace", unit
        )
        self.assertRegex(
            unit, r"(?m)^ExecStart=/nix/store/.+-hermes-dashboard/bin/hermes-dashboard$"
        )
        source = (ROOT / "modules/features/services/hermes-shared.nix").read_text()
        self.assertIn(
            "hermes dashboard --host 0.0.0.0 --port 9119 --skip-build --no-open",
            source,
        )
        self.assertIn("HERMES_DASHBOARD_BASIC_AUTH_USERNAME", source)
        self.assertIn("cd ${workspaceDir}", source)
        self.assertRegex(unit, r"(?m)^RestartPreventExitStatus=78$")
        self.assertEqual(result["hermesUid"], 986)
        self.assertTrue(result["hermesLinger"])
        self.assertIn("XDG_RUNTIME_DIR=/run/user/986", result["hermesUnit"])
        self.assertIn(
            "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/986/bus",
            result["hermesUnit"],
        )
        self.assertRegex(result["hermesUnit"], r"(?m)^After=.*user@986\.service")
        self.assertRegex(result["hermesUnit"], r"(?m)^Requires=.*user@986\.service")
        self.assertRegex(result["hermesUnit"], r"(?m)^ProtectHome=read-only$")
        self.assertRegex(unit, r"(?m)^Environment=.*SHELL=/nix/store/[^\s\"]+/bin/bash")
        self.assertRegex(unit, r"(?m)^Environment=.*PATH=.*-bash[^:/\s]*/bin")

        firewall = result["firewall"]
        self.assertTrue(firewall["enable"])
        self.assertEqual(firewall["trustedInterfaces"], ["lo"])
        self.assertNotIn(9119, firewall["allowedTCPPorts"])
        self.assertEqual(firewall["allowedTCPPortRanges"], [])
        self.assertEqual(firewall["extraInputRules"], "")
        self.assertNotIn("9119", firewall["extraCommands"])
        interfaces = list(firewall["allInterfaces"].values()) + list(
            firewall["interfaces"].values()
        )
        for interface in interfaces:
            self.assertNotIn(9119, interface["allowedTCPPorts"])
            self.assertEqual(interface["allowedTCPPortRanges"], [])

        self.assertEqual(result["route"]["middlewares"], ["trustedNetworks"])
        self.assertEqual(
            result["trustedNetworks"], ["192.168.178.0/24", "10.0.0.0/24"]
        )
        self.assertEqual(result["upstream"], [{"url": "http://127.0.0.1:9119"}])


if __name__ == "__main__":
    unittest.main()
