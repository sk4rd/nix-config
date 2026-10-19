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
      den.aspects.neon-flux-theme
      den.aspects.ollama
      den.aspects.openssh-key-only
      den.aspects.plasma
      den.aspects.printing-scanning
      den.aspects.yubikey-openpgp
    ];

    provides.to-users.includes = [
      den.aspects.brave
      den.aspects.cad
      den.aspects.gaming
      den.aspects.hermes-desktop
      den.aspects.libvirt
      den.aspects.media
      den.aspects.localsend
      den.aspects.plasma
      den.aspects.super-productivity
      den.aspects.vesktop
      den.aspects.yubikey-openpgp
      den.aspects.emacs
      den.aspects.neovim
      (den.lib.policy.when ({ hasAspect, ... }: hasAspect den.aspects.neon-flux-theme) {
        includes = [ den.aspects.neon-flux-theme ];
      })
    ];
  };
}
