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
      den.aspects.cad
      den.aspects.firefox
      den.aspects.gaming
      den.aspects.joplin-client
      den.aspects.libvirt
      den.aspects.media
      den.aspects.plasma
      den.aspects.vesktop
      den.aspects.yubikey-openpgp
    ];
  };
}
