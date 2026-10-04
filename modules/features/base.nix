{
  den.aspects.base.nixos = { pkgs, ... }: {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    programs.nix-ld = {
      enable = true;
      libraries = [ pkgs.glib ];
    };
  };
}
