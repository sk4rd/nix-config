{ ... }:

let
  monitor = {
    internal.identifier = "eDP-1";
    primary = monitor.internal;
  };
in {
  # Additional Hyprland settings for laptop
  wayland.windowManager.hyprland = {
    settings = {
      # Set-up monitor with 2x scaling
      monitor = "${monitor.internal.identifier}, 2880x1800@60, 0x0, 2";

      # Touchpad and drawing tablet configuration
      input = {
        touchpad = {
          disable_while_typing = true;
          natural_scroll = true;
          clickfinger_behavior = true;
          tap-to-click = true;
        };

        tablet.output = monitor.primary.identifier;
      };

      bind = [
        # Screen brightness control
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"

        # Volume control
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%-"
        ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 5%+"
      ];
    };
  };
}
