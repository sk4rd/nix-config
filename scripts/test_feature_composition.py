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

    def test_shared_hermes_creates_workspace_after_valid_mount_cwd(self):
        result = evaluate(f'''let
          c = (builtins.getFlake "{ROOT}").nixosConfigurations.nas.config;
        in {{ unit = c.systemd.units."hermes-serve.service".text; }}''')
        unit = result["unit"]
        self.assertRegex(unit, r"(?m)^WorkingDirectory=/srv/hermes$")
        self.assertRegex(unit, r"(?m)^AssertPathIsMountPoint=/srv/hermes$")
        self.assertRegex(unit, r"(?m)^RequiresMountsFor=/srv/hermes$")
        self.assertIn(
            "install -d -o hermes -g hermes -m 0750 /srv/hermes/workspace", unit
        )
        self.assertRegex(
            unit, r"(?m)^ExecStart=/nix/store/.+-hermes-serve/bin/hermes-serve$"
        )
        source = (ROOT / "modules/features/services/hermes-shared.nix").read_text()
        self.assertIn("cd ${workspaceDir}", source)


if __name__ == "__main__":
    unittest.main()
