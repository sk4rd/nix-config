{
  den.aspects.libvirt = {
    nixos = {
      programs.virt-manager.enable = true;
      virtualisation = {
        libvirtd = {
          enable = true;
          # Windows 11 guests require a TPM.
          qemu.swtpm.enable = true;
        };
        spiceUSBRedirection.enable = true;
      };
    };

    provides.to-users.user.extraGroups = [ "libvirtd" ];
  };
}
