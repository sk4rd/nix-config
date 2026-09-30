{ den, ... }:

{
  den.aspects.rustdesk.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.rustdesk-flutter ];
    };

  den.aspects.rustdesk-host = {
    includes = [ den.aspects.rustdesk ];

    nixos =
      { lib, pkgs, ... }:
      {
        # This is the remote-control endpoint, not an ID/relay server.
        # Follow upstream's service mode; it needs root to manage sessions/input.
        systemd.services.rustdesk = {
          description = "RustDesk remote desktop";
          wantedBy = [ "multi-user.target" ];
          requires = [ "network.target" ];
          after = [ "systemd-user-sessions.service" ];
          path = [ pkgs.procps ];
          environment = {
            PULSE_LATENCY_MSEC = "60";
            PIPEWIRE_LATENCY = "1024/48000";
          };
          serviceConfig = {
            Type = "simple";
            ExecStart = "${lib.getExe pkgs.rustdesk-flutter} --service";
            User = "root";
            KillMode = "mixed";
            TimeoutStopSec = 30;
            LimitNOFILE = 100000;
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
  };
}
