{
  config,
  lib,
  pkgs,
  ...
}:

let
  secretPath = config.sops.secrets."proxy_extra_hosts".path;
  markerStart = "# BEGIN work proxy_extra_hosts";
  markerEnd = "# END work proxy_extra_hosts";
in
{
  sops = {
    defaultSopsFile = ../../secrets/work.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."proxy_extra_hosts" = {
      owner = "root";
      mode = "0400";
    };
  };

  networking.proxy.default = "http://127.0.0.1:3128";

  wsl = {
    enable = true;
    wslConf.network.generateHosts = false;
  };

  networking.hostFiles = lib.mkForce [ ];

  system.activationScripts.workProxyExtraHosts.text = ''
    set -eu

    hostsFile=/etc/hosts
    tmpFile="$(${pkgs.coreutils}/bin/mktemp)"

    ${pkgs.gawk}/bin/awk '
      $0 == "'"${markerStart}"'" { skip=1; next }
      $0 == "'"${markerEnd}"'"   { skip=0; next }
      !skip { print }
    ' "$hostsFile" > "$tmpFile"

    {
      echo
      echo "${markerStart}"
      cat "${secretPath}"
      printf '\n'
      echo "${markerEnd}"
    } >> "$tmpFile"

    ${pkgs.coreutils}/bin/chmod 0644 "$tmpFile"
    ${pkgs.coreutils}/bin/mv "$tmpFile" "$hostsFile"
  '';

  system.stateVersion = "25.11";
}
