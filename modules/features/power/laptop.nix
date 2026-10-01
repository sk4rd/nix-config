{
  den.aspects.laptop-power.nixos = {
    # Explicit laptop policy, stronger than Plasma's default and retained if
    # the desktop environment changes.
    services.power-profiles-daemon.enable = true;
  };
}
