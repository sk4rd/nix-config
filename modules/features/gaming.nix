{ den, ... }:

{
  den.aspects.gaming = {
    includes = [
      den.aspects.flatpak
      (den.batteries.unfree [
        "steam"
        "steam-original"
        "steam-run"
        "steam-unwrapped"
      ])
    ];

    nixos =
      { pkgs, ... }:
      {
        programs = {
          steam = {
            enable = true;
            # In-home streaming and Remote Play Together.
            remotePlay.openFirewall = true;
            # Declarative Proton GE-Proton; newer versions can be added with
            # ProtonUp-Qt (in the Home Manager package set below).
            extraCompatPackages = [ pkgs.proton-ge-bin ];
          };

          gamemode.enable = true;
          # Per-game gamescope via `gamescope -f -- %command%` or Steam's toggle.
          gamescope.enable = true;
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        programs.mangohud.enable = true;

        home.packages = [
          pkgs.protontricks
          pkgs.protonup-qt
        ];

        # Keep Flathub and Bottles user-scoped; downloads happen after login,
        # outside Home Manager activation, and retry if the network is offline.
        systemd.user.services.bottles-flatpak = {
          Unit.Description = "Install Bottles from Flathub";
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "install-bottles-flatpak" ''
              set -eu
              ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub \
                https://flathub.org/repo/flathub.flatpakrepo
              ${pkgs.flatpak}/bin/flatpak install --user --assumeyes --noninteractive \
                flathub com.usebottles.bottles
            '';
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "60s";
            TimeoutStartSec = "15min";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };
}
