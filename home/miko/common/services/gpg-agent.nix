{ ... }:

{
  # GPG agent configuration
  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "gtk2";
    extraConfig = ''
      allow-emacs-pinentry
      allow-loopback-pinentry
    '';

  };
}

