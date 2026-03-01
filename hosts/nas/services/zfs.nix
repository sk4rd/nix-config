{ ... }:

{
  services.zfs = {
    trim.enable = false;

    expandOnBoot = "all";

    # Monthly scrub
    autoScrub.enable = true;

    autoSnapshot = {
      enable = true;
      hourly = 24;
      daily = 30;
      weekly = 8;
      monthly = 12;
    };
  };

  services.smartd.enable = true;
}
