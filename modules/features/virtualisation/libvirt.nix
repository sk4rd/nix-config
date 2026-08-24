{
  den.aspects.libvirt = {
    nixos = {
      programs.virt-manager.enable = true;
      virtualisation.libvirtd.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
    };

    provides.to-users.user.extraGroups = [ "libvirtd" ];
  };
}
