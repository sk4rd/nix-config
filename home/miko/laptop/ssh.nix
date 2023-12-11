{ ... }:

{
  # SSH client configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "desktop" = {
        hostname = "192.168.2.2";
        user = "miko";
        identityFile = "~/.ssh/id_ed25519_laptop_to_desktop";
      };
    };
  };
}

