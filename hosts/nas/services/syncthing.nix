{ ... }:

{
  services.syncthing = {
    enable = true;
    user = "miko";
    group = "miko";
    relay.enable = true;
    openDefaultPorts = true;
    dataDir = "/storage-pool/Private/miko";
  };
}
