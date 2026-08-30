{ den, ... }:

{
  den.aspects.plasma-workstation = {
    includes = [
      den.aspects.backup
      den.aspects.graphical
      den.aspects.gaming
      den.aspects.hardware
      den.aspects.libvirt
      den.aspects.nas-cifs
      den.aspects.openssh-key-only
      den.aspects.plasma
      den.aspects.printing-scanning
      den.aspects.yubikey-openpgp
    ];

    provides.to-users.includes = [
      den.aspects.gaming
      den.aspects.libvirt
      den.aspects.plasma
      den.aspects.yubikey-openpgp
    ];
  };
}
