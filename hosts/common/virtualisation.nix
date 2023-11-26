{ pkgs, ... }:

{
  # Virtualisation configuration
  virtualisation = {
    # Libvirt specific settings
    libvirtd = {
      enable = true;
      # Qemu settings
      qemu.ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      }
      # Virtual TPM
      qemu.swtpm.enable = true;
    };
    # Docker specific settings
    docker = {
      enable = true;
    };
    # USB redirection support
    spiceUSBRedirection.enable = true;
  };

  # Enable Spice vdagent
  services.spice-vdagent.enable = true;
}
