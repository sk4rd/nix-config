{ ... }:

{
  services.zfs = {
    trim.enable = true;
    expandOnBoot = "all";
    autoScrub.enable = true;
  };
}
