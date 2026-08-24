{ inputs, ... }:

{
  den.aspects.secrets.nixos.imports = [ inputs.sops-nix.nixosModules.sops ];
}
