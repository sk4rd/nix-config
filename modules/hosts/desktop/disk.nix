{
  den.aspects.desktop.nixos = {
    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-CT4000P3PSSD8_2339E879EA19";

      content = {
        type = "gpt";

        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";

            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          cryptroot = {
            size = "100%";

            content = {
              type = "luks";
              name = "cryptroot";
              extraFormatArgs = [ "--type=luks2" ];
              settings.allowDiscards = true;

              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
