{ ... }:

let
  # Primary and secondary monitor definitions
  monitor = {
    primary = {
      identifier = "DP-1";
      workspaces = [ 1 2 3 ];
    };
    secondary = {
      identifier = "HDMI-A-1";
      workspaces = [ 4 5 6 ];
    };
  };

  # Function to create workspace bindings
  mkWorkspaceBinding = monitorIdentifier: workspace:
    "${toString workspace}, monitor:${monitorIdentifier}";

  # Generate workspace bindings for a monitor
  generateBindings = m:
    builtins.map (ws: mkWorkspaceBinding m.identifier ws) m.workspaces;

in {
  # Additional Hyprland settings for desktop
  wayland.windowManager.hyprland = {
    settings = {
      # Define monitor settings and layout
      monitor = [
        "${monitor.primary.identifier}, 2560x1440@165, 1920x0, 1"
        "${monitor.secondary.identifier}, 1920x1080@60, 0x0, 1"
      ];

      # Bind workspaces to specific monitors
      workspace = (generateBindings monitor.primary)
        ++ (generateBindings monitor.secondary);

      # Drawing tablet monitor binding
      input = { tablet.output = monitor.primary.identifier; };
    };
  };
}
