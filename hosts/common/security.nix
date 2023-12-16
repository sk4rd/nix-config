{ ... }:

{
  # Allow unlocking with swaylock
  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };
}

