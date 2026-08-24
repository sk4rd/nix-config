{
  den.aspects.laptop.nixos = {
    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b444a481737ed";

      content = {
        type = "gpt";

        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";

            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [
                "-F"
                "32"
              ];
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

    swapDevices = [ ];
  };
}
