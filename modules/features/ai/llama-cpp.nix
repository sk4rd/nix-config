{ inputs, ... }:

let
  # Keep the downloaded GGUF and the Hermes model id in one place so they
  # cannot drift; `--alias` makes the OpenAI-compatible model id predictable.
  modelRepo = "unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:UD-Q4_K_XL";
  modelAlias = "qwen3-30b-a3b";
  qwenContextSize = 65536;

  # Hermes talks to the proxy socket; the socket starts the proxy, which
  # starts the server, which binds the internal port.
  hermesPort = 8080;
  serverPort = 8081;

  # Second endpoint: gpt-oss-20b, the on-device reasoning model. Same
  # on-demand shape on its own socket and server port, so both local models
  # can be offered in the picker at the same time.
  ossRepo = "ggml-org/gpt-oss-20b-GGUF:MXFP4";
  ossAlias = "gpt-oss-20b";
  ossContextSize = 131072;
  ossHermesPort = 8082;
  ossServerPort = 8083;

  # Flags for the second server. MXFP4 is the model's own quantization (the
  # Vulkan backend implements it); `reasoning-format = "deepseek"` is what
  # makes llama-server return the analysis in `message.reasoning_content`,
  # the field Hermes surfaces as the Thinking block.
  ossSettings = {
    host = "127.0.0.1";
    port = ossServerPort;
    "hf-repo" = ossRepo;
    alias = ossAlias;
    # gpt-oss-20b is trained for 131072 tokens; 11.3 GiB of weights plus q8_0
    # KV at that window still leaves the 20 GiB card headroom.
    ctx-size = ossContextSize;
    flash-attn = "on";
    cache-type-k = "q8_0";
    cache-type-v = "q8_0";
    reasoning = "on";
    reasoning-effort = "medium";
    reasoning-format = "deepseek";
    sleep-idle-seconds = 300;
    # Required for tool calling; without it llama-server ignores the `tools`
    # parameter and Hermes never sees a tool call.
    jinja = true;
  };
in

{
  # Local OpenAI-compatible model backend for Hermes Agent, served by
  # llama.cpp. The models are not loaded at boot: a socket proxy starts the
  # server on the first request and stops it again once idle, so the card is
  # only used while the agent is actually running. The GGUFs are downloaded
  # into the service caches on first use and are not stored in the repository.
  den.aspects.llama-cpp = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Release VRAM when the proxy exits. Conflicts alone would stop the
        # sibling and start this server concurrently; ordering lets the old
        # model release VRAM before --fit probes it for the new model.
        mkOnDemandServer = conflictingUnit: {
          wantedBy = lib.mkForce [ ];
          unitConfig = {
            StopWhenUnneeded = true;
            Conflicts = [ conflictingUnit ];
          };
          after = [ conflictingUnit ];
        };

        # Keep clients queued while the model loads (or downloads on first use).
        mkReadiness =
          name: port:
          pkgs.writeShellScript "wait-for-${name}" ''
            deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 3600 ))
            while [ "$(${pkgs.coreutils}/bin/date +%s)" -lt "$deadline" ]; do
              if ${pkgs.curl}/bin/curl --silent --fail --max-time 5 \
                "http://127.0.0.1:${toString port}/health" >/dev/null; then
                exit 0
              fi
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "${name} did not become healthy within an hour" >&2
            exit 1
          '';

        mkProxyEndpoint =
          {
            name,
            label,
            listenPort,
            serverPort,
          }:
          let
            dependencies = [
              "${name}.service"
              "${name}-proxy.socket"
            ];
          in
          {
            socket = {
              description = "Hermes endpoint that starts the ${label} server on demand";
              wantedBy = [ "sockets.target" ];
              listenStreams = [ "127.0.0.1:${toString listenPort}" ];
              # Pass the listening socket to the proxy so it accepts connections.
              socketConfig.Accept = false;
            };
            service = {
              description = "Socket-activated proxy to the ${label} server";
              requires = dependencies;
              after = dependencies;
              serviceConfig = {
                ExecStartPre = mkReadiness name serverPort;
                ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=300 127.0.0.1:${toString serverPort}";
                Type = "notify";
                TimeoutStartSec = "infinity";
                DynamicUser = true;
              };
            };
          };

        # services.llama-cpp is a singleton. Additional servers need a manual
        # unit with an isolated cache; keep gpt-oss's hardening intact here.
        mkManualServer =
          {
            name,
            description,
            settings,
            conflictingUnit,
          }:
          (mkOnDemandServer conflictingUnit)
          // {
            inherit description;
            after = [
              "network.target"
              conflictingUnit
            ];
            wants = [ "network.target" ];
            serviceConfig = {
              ExecStart = toString [
                (lib.getExe' pkgs.llama-cpp-vulkan "llama-server")
                (lib.cli.toCommandLine (name: {
                  option =
                    if lib.hasPrefix "-" name then
                      name
                    else if builtins.stringLength name > 1 then
                      "--${name}"
                    else
                      "-${name}";
                  sep = " ";
                  explicitBool = false;
                  formatArg = lib.generators.mkValueStringDefault { };
                }) settings)
              ];
              ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
              Restart = "on-failure";
              RestartSec = 300;

              DynamicUser = true;
              StateDirectory = name;
              CacheDirectory = name;
              WorkingDirectory = "/var/lib/${name}";
              Environment = [ "LLAMA_CACHE=/var/cache/${name}" ];

              AmbientCapabilities = [ "" ];
              CapabilityBoundingSet = [ "" ];
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              NoNewPrivileges = true;
              PrivateDevices = false; # Required for GPU support.
              PrivateMounts = true;
              PrivateTmp = true;
              PrivateUsers = true;
              ProcSubset = "pid";
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProtectSystem = "strict";
              RemoveIPC = true;
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_INET6"
                "AF_UNIX"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SystemCallArchitectures = "native";
              SystemCallErrorNumber = "EPERM";
              SystemCallFilter = [
                "@system-service"
                "~@privileged"
              ];
            };
          };

        qwenProxy = mkProxyEndpoint {
          name = "llama-cpp";
          label = "llama.cpp";
          listenPort = hermesPort;
          inherit serverPort;
        };
        ossProxy = mkProxyEndpoint {
          name = "llama-cpp-oss";
          label = "gpt-oss-20b";
          listenPort = ossHermesPort;
          serverPort = ossServerPort;
        };
      in
      {
        services.llama-cpp = {
          enable = true;
          package = pkgs.llama-cpp-vulkan;
          settings = {
            host = "127.0.0.1";
            port = serverPort;
            "hf-repo" = modelRepo;
            alias = modelAlias;
            ctx-size = qwenContextSize;
            flash-attn = "on";
            # Quantized KV keeps the 64k context within the 20 GiB card. The
            # default --fit (on) then picks how many layers fit in VRAM.
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            # Also unload the model while the proxy is still connected but the
            # agent is idle, then reload it on the next request.
            sleep-idle-seconds = 300;
            # Required for tool calling; without it llama-server ignores the
            # `tools` parameter and Hermes never sees a tool call.
            jinja = true;
          };
        };

        # Both models cannot be resident at once (19.1 GiB + ~16 GiB does
        # not fit 20 GiB). Starting either server stops the other, while both
        # sockets stay available without loading a model at boot.
        systemd = {
          services = {
            llama-cpp = mkOnDemandServer "llama-cpp-oss.service";
            llama-cpp-oss = mkManualServer {
              name = "llama-cpp-oss";
              description = "llama.cpp server for gpt-oss-20b (started on demand)";
              settings = ossSettings;
              conflictingUnit = "llama-cpp.service";
            };
            llama-cpp-proxy = qwenProxy.service;
            llama-cpp-oss-proxy = ossProxy.service;
          };
          sockets = {
            llama-cpp-proxy = qwenProxy.socket;
            llama-cpp-oss-proxy = ossProxy.socket;
          };
        };
      };

    homeManager = {
      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      # Home Manager stays authoritative for these keys: each activation
      # deep-merges the endpoints into config.yaml and keeps other runtime
      # keys. Gateway and backend stay disabled, so this writes the config
      # without starting a daemon.
      services.hermes-agent = {
        enable = true;

        settings = {
          model = {
            # `llama-cpp` resolves to the endpoint below. A bare `custom`
            # provider would not: it falls back to the first entry of
            # `custom_providers`, which is how a stale LM Studio endpoint on
            # port 1234 captured every request.
            #
            # The key must NOT be `llamacpp`: the desktop renderer filters that
            # exact slug out of the composer model picker unless the app is
            # launched with `--local` (it reserves the slug for its own managed
            # local runtime). With `llamacpp` the row is missing from the
            # picker even though `model.options` serves it.
            provider = "llama-cpp";
            default = modelAlias;
            # llama-server serves the OpenAI chat-completions API.
            api_mode = "chat_completions";
          };

          providers = {
            llama-cpp = {
              # The picker labels the row with this name; without it the label is
              # the provider key (`llama-cpp`).
              name = "llama.cpp (local)";
              base_url = "http://127.0.0.1:${toString hermesPort}/v1";
              model = modelAlias;
              # Matches ctx-size above, so the picker does not have to probe
              # the server for it.
              models.${modelAlias}.context_length = qwenContextSize;
              # No live /models probe: a dict-shaped `models:` still gets probed
              # by default, and these endpoints are socket-activated — listing
              # models would pull the server in (and, for the second row, start
              # an 11 GiB download and stop whichever model is running). The row
              # stays populated from `model` plus the declared ids above.
              discover_models = false;
            };

            llama-cpp-oss = {
              name = "gpt-oss-20b (local)";
              base_url = "http://127.0.0.1:${toString ossHermesPort}/v1";
              model = ossAlias;
              api_mode = "chat_completions";
              # Matches ctx-size above.
              models.${ossAlias}.context_length = ossContextSize;
              # See the note on the row above: never probe a socket-activated
              # endpoint from the picker.
              discover_models = false;
            };

            # The pre-rename `providers.llamacpp` block from earlier activations
            # stays on disk (the merge cannot delete keys) and is retired here;
            # `enabled = false` hides it from the picker, /models, the runtime
            # resolver and doctor.
            llamacpp.enabled = false;

            # The earlier LM Studio endpoint runs nowhere on this host. Retire
            # its provider block, which the activation merge cannot delete.
            custom.enabled = false;
          };

          # Per-model capability patch that always beats the models.dev
          # catalog. gpt-oss-20b reasons (llama-server returns the analysis in
          # `message.reasoning_content`) and calls tools; declaring it here is
          # what offers the Thinking controls for this row instead of leaving
          # them to a catalog guess.
          model_overrides."llama-cpp-oss".${ossAlias} = {
            supports_tools = true;
            supports_reasoning = true;
            context_window = ossContextSize;
            model_family = "gpt-oss";
          };

          # The legacy list goes away: this module owns both keys from here on,
          # so endpoints added through the desktop UI do not survive an
          # activation. Declare them in this file instead.
          custom_providers = [ ];
        };
      };
    };
  };
}
