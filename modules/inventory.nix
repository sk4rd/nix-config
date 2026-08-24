{
  den.hosts.x86_64-linux.desktop = {
    hostName = "desktop";
    users.miko = { };
  };

  den.hosts.x86_64-linux.laptop = {
    hostName = "laptop";
    users.miko = { };
  };

  den.hosts.x86_64-linux.vm = {
    # Preserve the current network identity while using `vm` as the flake target.
    hostName = "nixos";
    users.miko = { };
  };

  # The same user aspect can also be activated outside NixOS.
  den.homes.x86_64-linux.miko = { };
}
