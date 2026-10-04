{ den, ... }:

let
  inherit (import ../../../lib/nas-service-helpers.nix) mountSafety httpsRoute;
in
{
  den.aspects.searxng.includes = [ den.aspects.nas-ingress ];

  den.aspects.searxng.nixos =
    { config, pkgs, ... }:
    let
      settingsFile = config.sops.templates."searxng.settings.yml".path;
    in
    {
      sops.secrets."nas/searxng/secret_key" = {
        mode = "0400";
        restartUnits = [ "docker-searxng.service" ];
      };

      # The entrypoint generates a key only when settings.yml is absent; it never
      # rewrites existing files. SearXNG rejects `ultrasecretkey`, so render the
      # real key into its settings via SOPS rather than storing it in plaintext.
      sops.templates."searxng.settings.yml" = {
        content = ''
          use_default_settings: true

          server:
            secret_key: ${config.sops.placeholder."nas/searxng/secret_key"}
            # Preserve the image template's proxying; the packaged default is false.
            image_proxy: true

          # Unlisted formats return HTTP 403; Hermes' web_search requires json.
          # Lists replace defaults rather than merging, so retain html explicitly.
          search:
            formats:
              - html
              - json

          # Overrides merge by engine name, retaining packaged category engines.
          # Disabled engines hit CAPTCHA/429 on this NAS; duckduckgo web and mwmbl
          # worked through the same egress IP. Preferences permits manual retesting.
          engines:
            - name: brave
              disabled: true
            - name: duckduckgo
              disabled: true
            - name: google cse
              disabled: true
            - name: startpage
              disabled: true
            - name: duckduckgo web
              disabled: false
            - name: mwmbl
              disabled: false
        '';
        mode = "0400";
        # Content changes keep the same secret path and unit text; restart to reload.
        restartUnits = [ "docker-searxng.service" ];
      };

      virtualisation = {
        oci-containers.containers.searxng = {
          image = "ghcr.io/searxng/searxng@sha256:b36af7984b87191b595bc5301418ed6432c047668a4547ab531a7439b816fac3";
          pull = "missing";
          environment = {
            SEARXNG_BASE_URL = "https://search.sk4rd.com";
          };
          # The root entrypoint's default FORCE_OWNERSHIP chowns mounts to searxng.
          volumes = [
            "/srv/searxng/config:/etc/searxng"
            "/srv/searxng/cache:/var/cache/searxng"
          ];
          ports = [ "127.0.0.1:8080:8080/tcp" ];
        };
      };

      services.traefik.dynamicConfigOptions.http = httpsRoute {
        router = "search";
        backend = "searxng";
        domain = "search.sk4rd.com";
        url = "http://127.0.0.1:8080";
        exposure = "trustedNetworks";
      };

      systemd.services.docker-searxng = mountSafety [ "/srv/searxng" ] // {
        # Reinstall before each start: settings are read once, and an existing file
        # bypasses entrypoint key generation. 0600/0750 excludes other local accounts.
        # This image runs as root; FORCE_OWNERSHIP chowns the mount to searxng.
        # Revisit permissions only if a future image drops privileges without chowning.
        serviceConfig.ExecStartPre = [
          "+${pkgs.coreutils}/bin/install -d -m 0750 /srv/searxng/config"
          "+${pkgs.coreutils}/bin/install -m 0600 ${settingsFile} /srv/searxng/config/settings.yml"
        ];
      };
    };
}
