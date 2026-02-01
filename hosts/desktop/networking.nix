{ ... }:

{
  networking = {
    hostName = "desktop";
    useNetworkd = true;
    useDHCP = false;
    interfaces.enp10s0.useDHCP = true;
    interfaces.br0.useDHCP = true;
    bridges.br0.interfaces = [ "enp10s0" ];
  };
}
