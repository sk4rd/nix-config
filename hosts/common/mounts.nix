{ pkgs, config, ... }:

{
  environment.systemPackages = [ pkgs.cifs-utils ];

  fileSystems."/mnt/nas" = {
    device = "//192.168.178.3/private";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "credentials=${config.sops.secrets."nas/credentials".path}"
      "uid=1000"
      "gid=100"
    ];
  };
}
