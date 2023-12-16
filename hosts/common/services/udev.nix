{ ... }:

{
  # Apply udev workaround for Sennheiser GSX 1000 volume wheel
  services.udev.extraHwdb = ''
    evdev:input:b0003v1395p005E*
      KEYBOARD_KEY_C00EA=reserved
  '';
}

