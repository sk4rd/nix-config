{ den, lib, ... }:

{
  # Den enables Home Manager only for hosts that contain a Home Manager user.
  # Apply repository-wide integration settings to exactly those hosts.
  den.schema.host.includes = [
    (
      { host }:
      lib.optionalAttrs (host.home-manager.enable or false) {
        nixos.home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      }
    )
  ];
}
