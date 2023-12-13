{ ... }:

{
  networking = {
    hostName = "desktop";
    interfaces = {
      enp10s0.ipv4.addresses = [{
        address = "192.168.2.2";
        prefixLength = 24;
      }];
    };
  };
}
