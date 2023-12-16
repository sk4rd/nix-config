{ ... }:

{
  services.openssh = {
    enable = true;
    # Require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };
}

