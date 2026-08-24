{ den, ... }:

{
  den.aspects.yubikey-openpgp = {
    nixos.services.pcscd.enable = true;

    homeManager =
      { pkgs, ... }:
      {
        programs.gpg = {
          enable = true;
          scdaemonSettings.disable-ccid = true;
        };

        services.gpg-agent = {
          enable = true;
          enableScDaemon = true;
          enableSshSupport = true;
          sshKeys = [ "B2C75C046C757FED9A1359BB566EB14A969EB784" ];

          pinentry = {
            package = pkgs.pinentry-qt;
            program = "pinentry-qt";
          };
        };
      };
  };
}
