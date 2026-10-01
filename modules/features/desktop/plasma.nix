{
  den.aspects.plasma.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = true;

      # SDDM upstream delegates authentication to `login`, whose fingerprint
      # prompt blocks password entry. Preserve that stack's other auth policy,
      # but materialise it here without fprintd. Account/session/password stacks
      # still include login, so wallet opening and session setup stay unchanged.
      security.pam.services.sddm = {
        fprintAuth = false;
        rules.auth = lib.mkForce (
          # Evaluated args already contain settings; do not append them twice.
          lib.mapAttrs (_: rule: (builtins.removeAttrs rule [ "name" ]) // { settings = { }; }) (
            lib.filterAttrs (
              name: rule: name != "fprintd" && rule.enable
            ) config.security.pam.services.login.rules.auth
          )
        );
      };

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        aurorae
        discover
        elisa
        khelpcenter
        krdp
        plasma-browser-integration
        plasma-keyboard
        plasma-workspace-wallpapers
        qrca
        qttools
        qtvirtualkeyboard
        union
      ];

      programs.kde-pim.enable = false;
    };

}
