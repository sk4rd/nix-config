{
  den.aspects.libvirt = {
    nixos = {
      programs.virt-manager.enable = true;
      virtualisation = {
        libvirtd = {
          enable = true;
          # Emulated TPM for modern guests (e.g. Windows 11); OVMF/UEFI firmware is
          # included with the QEMU package by default.
          qemu.swtpm.enable = true;
        };
        spiceUSBRedirection.enable = true;
      };
    };

    provides.to-users.user.extraGroups = [ "libvirtd" ];
  };
}
