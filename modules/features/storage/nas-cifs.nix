{
  den.aspects.nas-cifs.nixos =
    { config, pkgs, ... }:
    let
      mountOptions = [
        "_netdev"
        "x-systemd.automount"
        "nofail"
        "x-systemd.idle-timeout=60s"
        "x-systemd.mount-timeout=5s"
        "credentials=${config.sops.secrets."nas/credentials".path}"
        "uid=miko"
        "gid=users"
        "forceuid"
        "forcegid"
        "file_mode=0600"
        "dir_mode=0700"
        "nosuid"
        "nodev"
        "vers=3.1.1"
        "seal"
      ];
    in
    {
      environment.systemPackages = [ pkgs.cifs-utils ];

      sops.secrets."nas/credentials" = {
        sopsFile = ../../../secrets/nas-cifs.yaml;
        mode = "0400";
      };

      fileSystems = {
        "/mnt/nas/documents" = {
          device = "//192.168.178.3/Documents";
          fsType = "cifs";
          options = mountOptions;
        };
        "/mnt/nas/torrents" = {
          device = "//192.168.178.3/Torrents";
          fsType = "cifs";
          options = mountOptions;
        };
      };
    };
}
