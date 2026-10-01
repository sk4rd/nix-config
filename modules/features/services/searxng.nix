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

      # The container entrypoint only generates a `server.secret_key` when
      # /etc/searxng/settings.yml does NOT exist, and never rewrites an existing file
      # (container/entrypoint.sh, setup()). It writes container/settings.template.yml
      # verbatim, i.e. `use_default_settings: true` plus `server.secret_key` and
      # `server.image_proxy: true`. SearXNG treats a key left at the template's
      # `ultrasecretkey` as fatal — searx/webapp.py:1356 logs and then sys.exit(1)s —
      # so the worker exits, the unit restart-loops and Traefik answers 502. The key
      # therefore has to be in the file the container reads, and the file has to be
      # rendered from sops because a plaintext settings.yml cannot carry it.
      sops.templates."searxng.settings.yml" = {
        content = ''
          use_default_settings: true

          server:
            secret_key: ${config.sops.placeholder."nas/searxng/secret_key"}
            # Matches the image's own settings template, which the entrypoint used to
            # write into this file; without it the merge would fall back to the
            # packaged default (false) and silently stop proxying result images.
            image_proxy: true

          # SearXNG denies every output format that is not listed here with HTTP 403
          # (searx/webapp.py: `if output_format not in settings['search']['formats']`).
          # The packaged default is `html` only, so API clients — Hermes' web_search
          # asks for /search?format=json — were refused outright. A list value is
          # replaced, not merged, so `html` has to be repeated here.
          search:
            formats:
              - html
              - json

          # Merge overrides by engine name, retaining the packaged category engines.
          # The HTML DuckDuckGo endpoint and these other default web engines returned
          # CAPTCHA/429 on this instance. DuckDuckGo's web endpoint and Mwmbl were
          # verified to return results through the same NAS egress IP.
          # Disabled engines remain available for manual testing in Preferences.
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
        # An edit to `content` re-renders the same /run/secrets path and leaves the
        # unit text unchanged, so without this a switch would not restart the container
        # and the host would keep reading the previous file.
        restartUnits = [ "docker-searxng.service" ];
      };

      virtualisation = {
        oci-containers.containers.searxng = {
          image = "ghcr.io/searxng/searxng@sha256:b36af7984b87191b595bc5301418ed6432c047668a4547ab531a7439b816fac3";
          pull = "missing";
          environment = {
            SEARXNG_BASE_URL = "https://search.sk4rd.com";
          };
          # The entrypoint runs as root and FORCE_OWNERSHIP (default) chowns the
          # mounted volumes to searxng on start, so no host-side chown is needed.
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
        # The container reads settings.yml once at startup, so the repository-owned file
        # is reinstalled before every start rather than edited on the host: the file now
        # exists at every start, which also means the entrypoint's generate-a-random-key
        # branch can never fire again. 0600 in a 0750 directory keeps the key off other
        # local accounts; the image publishes no USER directive, so the entrypoint and
        # the app run as root (the root-only certificate step in its journal proves it)
        # and the entrypoint's FORCE_OWNERSHIP chown to searxng leaves the owner able to
        # read it. Only widen this if a future image drops to an unprivileged user
        # without chowning the mount.
        serviceConfig.ExecStartPre = [
          "+${pkgs.coreutils}/bin/install -d -m 0750 /srv/searxng/config"
          "+${pkgs.coreutils}/bin/install -m 0600 ${settingsFile} /srv/searxng/config/settings.yml"
        ];
      };
    };
}
