{ pkgs, ... }:

{
  programs = {
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
        mangohud
        gamemode
      ];
    };

    localsend = {
      enable = true;
      openFirewall = true;
    };
  };
}
