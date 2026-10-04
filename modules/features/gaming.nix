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
            remotePlay.openFirewall = true;
            # ProtonUp-Qt can install newer versions alongside this pinned package.
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

        # Download user-scoped Bottles after login, not during HM activation;
        # retry on network failure.
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
