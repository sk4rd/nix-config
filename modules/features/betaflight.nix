{
  den.aspects.betaflight.nixos =
    { pkgs, ... }:
    {
      services.udev.packages = [
        (pkgs.writeTextDir "lib/udev/rules.d/70-betaflight.rules" ''
          # Tag devices before 73-seat-late.rules grants the active seat user access.
          SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0483", ATTR{idProduct}=="5740", ATTR{manufacturer}=="Betaflight", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"
          SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", ATTRS{manufacturer}=="Betaflight", TAG+="uaccess", ENV{ID_MM_PORT_IGNORE}="1"
        '')
      ];
    };
}
