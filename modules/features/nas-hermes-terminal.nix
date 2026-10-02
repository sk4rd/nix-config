{
  den.aspects.nas-hermes-terminal.homeManager =
    { pkgs, ... }:
    let
      launcher = pkgs.writeShellApplication {
        name = "nas-hermes-terminal";
        runtimeInputs = [ pkgs.openssh ];
        text = builtins.readFile ./nas-hermes-terminal.sh;
      };
    in
    {
      home.packages = [ launcher ];
      xdg.desktopEntries.nas-hermes-terminal = {
        name = "NAS Hermes Terminal";
        comment = "Open the NAS workspace as Hermes, with Git ready to use";
        exec = "${launcher}/bin/nas-hermes-terminal";
        icon = "utilities-terminal";
        terminal = true;
        categories = [
          "System"
          "TerminalEmulator"
        ];
      };
    };
}
