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
    def test_nas_secret_declarations_belong_to_consumers(self):
        result = evaluate(f'''let
          policy = (import {ROOT}/modules/features/credentials/nas-secrets.nix).den.aspects.nas-secrets;
          den.aspects.nas-secrets = policy;
          ingress = (import {ROOT}/modules/features/services/nas-ingress.nix {{ inherit den; }}).den.aspects.nas-ingress;
          torrenting = (import {ROOT}/modules/features/services/torrenting.nix {{ inherit den; }}).den.aspects.torrenting;
          networking = (import {ROOT}/modules/hosts/nas/networking.nix).den.aspects.nas;
        in {{
          policySecrets = policy.nixos.sops.secrets or {{}};
          ingressSecrets = builtins.foldl'
            (secrets: aspect: secrets // (aspect.nixos.sops.secrets or {{}}))
            (ingress.nixos {{ config = {{}}; }}).sops.secrets ingress.includes;
          torrentSecrets = (torrenting.nixos {{ config = {{}}; pkgs = {{}}; lib = {{}}; }}).sops.secrets;
          wireguardSecrets = (networking.nixos {{ config = {{}}; }}).sops.secrets or {{}};
          file = toString policy.nixos.sops.defaultSopsFile;
          sshKeyPaths = policy.nixos.sops.age.sshKeyPaths;
        }}''')
        self.assertEqual(result["policySecrets"], {})
        self.assertEqual(result["ingressSecrets"], {
            "nas/cloudflare/dns_api_token": {
                "mode": "0400", "restartUnits": ["ddclient.service", "traefik.service"],
            },
        })
        torrent_secret = {"mode": "0400", "restartUnits": ["docker-qbittorrent-vpn.service"]}
        self.assertEqual(result["torrentSecrets"], {
            "nas/qbittorrent/webui_password": torrent_secret,
            "nas/protonvpn/wireguard_private_key": torrent_secret,
        })
        wireguard_secret = {"mode": "0400", "restartUnits": ["wg-quick-wg0.service"]}
        self.assertEqual(result["wireguardSecrets"], {
            "nas/wireguard/server_key": wireguard_secret,
            "nas/wireguard/phone_psk": wireguard_secret,
        })
        self.assertTrue(result["file"].endswith("/secrets/nas.yaml"))
        self.assertEqual(result["sshKeyPaths"], ["/etc/ssh/ssh_host_ed25519_key"])

    def test_dashboard_composes_its_widget_credential_provider(self):
        result = evaluate(f'''let
          f = builtins.getFlake "{ROOT}";
          probe = f.inputs.flake-parts.lib.mkFlake {{ inputs = f.inputs; }}
            ({{ den, ... }}: {{
              imports = [ (f.inputs.import-tree {ROOT}/modules) ];
              den.hosts.x86_64-linux.kiss-dashboard = {{}};
              den.aspects.kiss-dashboard.includes = [ den.aspects.dashboard ];
            }});
          c = probe.nixosConfigurations.kiss-dashboard.config;
          password = c.sops.placeholder."nas/qbittorrent/webui_password" or null;
        in {{
          names = builtins.attrNames c.sops.secrets;
          inherit password;
          template = if password != null then
            c.sops.templates."homepage-services.yaml".content else null;
        }}''')
        self.assertEqual(result["names"], [
            "nas/cloudflare/dns_api_token",
            "nas/protonvpn/wireguard_private_key",
            "nas/qbittorrent/webui_password",
        ])
        self.assertIsNotNone(result["password"])
        self.assertIn(f'password: {result["password"]}', result["template"])

    def test_provisioning_and_backup_follow_sops_path_overrides(self):
        result = evaluate(f'''let
          f = builtins.getFlake "{ROOT}";
          probe = f.inputs.flake-parts.lib.mkFlake {{ inputs = f.inputs; }} {{
            imports = [ (f.inputs.import-tree {ROOT}/modules) ];
            den.aspects.nas.nixos.sops.secrets = {{
              "nas/prowlarr/username".path = "/run/custom/prowlarr-user";
              "nas/prowlarr/password".path = "/run/custom/prowlarr-password";
              "nas/qbittorrent/webui_password".path = "/run/custom/qbittorrent-password";
            }};
            den.aspects.backup.nixos.sops.secrets."backup/ssh_key".path = "/run/custom/backup key";
          }};
          c = probe.nixosConfigurations.nas.config;
        in {{
          prowlarr = c.systemd.services.prowlarr-configure.environment;
          qbittorrent = c.systemd.services.qbittorrent-config.environment;
          units = {{
            prowlarr = c.systemd.units."prowlarr-configure.service".text;
            qbittorrent = c.systemd.units."qbittorrent-config.service".text;
          }};
          volumes = c.virtualisation.oci-containers.containers.qbittorrent-vpn.volumes;
          ssh = builtins.mapAttrs (_: h: h.config.programs.ssh.extraConfig)
            probe.nixosConfigurations;
        }}''')
        expected = {
            "PROWLARR_USERNAME_FILE": "/run/custom/prowlarr-user",
            "PROWLARR_PASSWORD_FILE": "/run/custom/prowlarr-password",
            "QBITTORRENT_PASSWORD_FILE": "/run/custom/qbittorrent-password",
        }
        for name, path in expected.items():
            self.assertEqual(result["prowlarr"].get(name), path)
            self.assertIn(f"{name}={path}", result["units"]["prowlarr"])
        self.assertEqual(result["qbittorrent"].get("QBITTORRENT_PASSWORD_FILE"), expected["QBITTORRENT_PASSWORD_FILE"])
        self.assertIn("QBITTORRENT_PASSWORD_FILE=/run/custom/qbittorrent-password", result["units"]["qbittorrent"])
        self.assertIn("/run/custom/qbittorrent-password:/run/secrets/qbittorrent-webui-password:ro", result["volumes"])
        for host in ("desktop", "laptop", "wsl"):
            self.assertIn('IdentityFile "/run/custom/backup key"', result["ssh"][host])
        self.assertNotIn("/run/custom/backup key", result["ssh"]["nas"])

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
