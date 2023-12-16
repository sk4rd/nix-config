{ pkgs, ... }:

{
  # Cupsd configuration for printing
  services.printing = {
    enable = true;
    drivers = with pkgs; [ postscript-lexmark ];
  };
}

