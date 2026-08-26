{ lib, ... }:

{
  den.schema.host.options.zfs.pools = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "ZFS pools to auto-scrub monthly.";
  };

  den.aspects.zfs-storage.nixos =
    { host, ... }:
    {
      services = {
        smartd = {
          enable = true;
          autodetect = true;
        };

        zfs = {
          autoScrub = {
            enable = true;
            interval = "monthly";
            pools = host.zfs.pools;
          };
          # Retention can destroy pre-migration snapshots. Re-enable only after
          # the existing snapshot history and desired policy have been reviewed.
          autoSnapshot.enable = false;
          expandOnBoot = "disabled";
          trim.enable = false;
        };
      };
    };
}
