{
  # Explicit mount points, not inferred from a service's volume subdirectories.
  mountSafety = mounts: {
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
    unitConfig = {
      RequiresMountsFor = mounts;
      AssertPathIsMountPoint = mounts;
    };
  };

  # Exposure is mandatory: omitting an allow-list must be a conscious decision.
  httpsRoute =
    {
      router,
      backend,
      domain,
      url,
      exposure,
      passHostHeader ? null,
    }:
    assert builtins.elem exposure [
      "public"
      "trustedNetworks"
    ];
    {
      routers.${router} = {
        rule = "Host(`${domain}`)";
        entryPoints = [ "websecure" ];
        service = backend;
        tls.certResolver = "cloudflare";
      }
      // (if exposure == "trustedNetworks" then { middlewares = [ "trustedNetworks" ]; } else { });
      services.${backend}.loadBalancer = {
        servers = [ { inherit url; } ];
      }
      // (if passHostHeader == null then { } else { inherit passHostHeader; });
    };
}
