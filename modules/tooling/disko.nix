{ inputs, ... }:

{
  perSystem =
    { system, ... }:
    {
      packages.disko = inputs.disko.packages.${system}.disko;
    };
}
