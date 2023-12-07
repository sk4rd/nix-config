{ ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    # Screen settings
    monitor = eDP-1, 2880x1800@60, 0x0, 2
    input {
      touchpad {
        disable_while_typing = true
        natural_scroll = true
        clickfinger_behavior = true
        tap-to-click = true
      }

      tablet {
        output = eDP-1
      }
    }

    bind = ,XF86MonBrightnessDown, exec, brightnessctl set 5%-
    bind = ,XF86MonBrightnessUp, exec, brightnessctl set 5%+
  '';
}
