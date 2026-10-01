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

    def test_local_model_metadata_matches_server_context(self):
        result = evaluate(f'''let
          c = (builtins.getFlake "{ROOT}").nixosConfigurations.desktop.config;
          s = c.home-manager.users.miko.services.hermes-agent.settings;
        in {{
          qwenServer = c.services.llama-cpp.settings.ctx-size;
          qwenMetadata = s.providers.llama-cpp.models.qwen3-30b-a3b.context_length;
          ossCommand = c.systemd.services.llama-cpp-oss.serviceConfig.ExecStart;
          ossMetadata = s.providers.llama-cpp-oss.models.gpt-oss-20b.context_length;
          ossOverride = s.model_overrides.llama-cpp-oss.gpt-oss-20b.context_window;
        }}''')
        self.assertEqual(result["qwenServer"], result["qwenMetadata"])
        self.assertEqual(result["ossMetadata"], result["ossOverride"])
        command = result["ossCommand"].split()
        self.assertEqual(int(command[command.index("--ctx-size") + 1]), result["ossMetadata"])


if __name__ == "__main__":
    unittest.main()
