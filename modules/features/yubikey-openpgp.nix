{
  den.aspects.yubikey-openpgp = {
    nixos.services.pcscd.enable = true;

    homeManager =
      { host, pkgs, ... }:
      {
        programs.gpg = {
          enable = true;
          scdaemonSettings.disable-ccid = true;
        };

        services.gpg-agent = {
          enable = true;
          enableScDaemon = true;
          enableSshSupport = true;
          sshKeys = [ "F4E029FE36A682470371788A61692D508CDF9CE9" ];

          pinentry =
            if host.wsl.enable or false then
              {
                package = pkgs.pinentry-curses;
                program = "pinentry-curses";
              }
            else
              {
                package = pkgs.pinentry-qt;
                program = "pinentry-qt";
              };
        };
      };
  };
}
