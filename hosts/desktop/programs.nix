{ ... }:

{
  programs.git = {
    enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.ssh.startAgent = false;
}
