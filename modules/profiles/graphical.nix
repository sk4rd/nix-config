{ den, ... }:

{
  den.aspects.graphical.includes = [
    den.aspects.appimage
    den.aspects.networking
    den.aspects.pipewire
  ];
}
