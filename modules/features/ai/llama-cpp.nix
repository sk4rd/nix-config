{ den, inputs, ... }:

let
  # Keep the downloaded GGUF and the Hermes model id in one place so they
  # cannot drift; `--alias` makes the OpenAI-compatible model id predictable.
  modelRepo = "unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:UD-Q4_K_XL";
  modelAlias = "qwen3-30b-a3b";

  # Hermes talks to the proxy socket; the socket starts the proxy, which
  # starts the server, which binds the internal port.
  hermesPort = 8080;
  serverPort = 8081;

  # Second endpoint: gpt-oss-20b, the on-device reasoning model. Same
  # on-demand shape on its own socket and server port, so both local models
  # can be offered in the picker at the same time.
  ossRepo = "ggml-org/gpt-oss-20b-GGUF:MXFP4";
  ossAlias = "gpt-oss-20b";
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
    ctx-size = 131072;
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
      {
        services.llama-cpp = {
          enable = true;
          package = pkgs.llama-cpp-vulkan;
          settings = {
            host = "127.0.0.1";
            port = serverPort;
            "hf-repo" = modelRepo;
            alias = modelAlias;
            ctx-size = 65536;
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

        # Do not load the model at boot. The proxy pulls the server in on the
        # first connection, and the socket costs nothing until then.
        systemd.services.llama-cpp = {
          wantedBy = lib.mkForce [ ];
          unitConfig = {
            # Once the proxy exits, nothing needs the server, so release the
            # process and its VRAM too.
            StopWhenUnneeded = true;
            # Both models cannot be resident at once (19.1 GiB + ~16 GiB does
            # not fit 20 GiB). Starting either server stops the other, so a
            # switch in the picker can never double-book the card.
            Conflicts = [ "llama-cpp-oss.service" ];
          };
          # Conflicts= on its own does not order the two jobs: systemd would
          # stop the sibling and start this server at the same time, so the
          # new one could probe VRAM while the old model still holds it (and
          # --fit would then quietly shrink the context instead of failing).
          after = [ "llama-cpp-oss.service" ];
        };

        systemd.sockets.llama-cpp-proxy = {
          description = "Hermes endpoint that starts the llama.cpp server on demand";
          wantedBy = [ "sockets.target" ];
          listenStreams = [ "127.0.0.1:${toString hermesPort}" ];
          # Pass the listening socket to the proxy so it accepts connections.
          socketConfig.Accept = false;
        };

        systemd.services.llama-cpp-proxy = {
          description = "Socket-activated proxy to the llama.cpp server";
          requires = [
            "llama-cpp.service"
            "llama-cpp-proxy.socket"
          ];
          after = [
            "llama-cpp.service"
            "llama-cpp-proxy.socket"
          ];
          serviceConfig = {
            # The server loads (and on first use downloads) the model before it
            # listens, so keep the client queued in the socket until healthy.
            ExecStartPre = pkgs.writeShellScript "wait-for-llama-cpp" ''
              deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 3600 ))
              while [ "$(${pkgs.coreutils}/bin/date +%s)" -lt "$deadline" ]; do
                if ${pkgs.curl}/bin/curl --silent --fail --max-time 5 \
                  "http://127.0.0.1:${toString serverPort}/health" >/dev/null; then
                  exit 0
                fi
                ${pkgs.coreutils}/bin/sleep 1
              done
              echo "llama-cpp did not become healthy within an hour" >&2
              exit 1
            '';
            ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=300 127.0.0.1:${toString serverPort}";
            Type = "notify";
            TimeoutStartSec = "infinity";
            DynamicUser = true;
          };
        };

        # ── gpt-oss-20b endpoint ──────────────────────────────────────────
        # A copy of the server unit above rather than a second
        # `services.llama-cpp`: that module is a singleton, and this endpoint
        # needs its own port, its own model cache and the same
        # stop-when-idle lifecycle. Keep the two in step when either changes.
        systemd.services.llama-cpp-oss = {
          description = "llama.cpp server for gpt-oss-20b (started on demand)";
          # Never at boot: the proxy below pulls it in on the first connection.
          wantedBy = lib.mkForce [ ];
          unitConfig = {
            StopWhenUnneeded = true;
            Conflicts = [ "llama-cpp.service" ];
          };
          # See the note on llama-cpp.service: ordering, not just the conflict.
          after = [
            "network.target"
            "llama-cpp.service"
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
              }) ossSettings)
            ];
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Restart = "on-failure";
            RestartSec = 300;

            DynamicUser = true;
            StateDirectory = "llama-cpp-oss";
            CacheDirectory = "llama-cpp-oss";
            WorkingDirectory = "/var/lib/llama-cpp-oss";
            Environment = [ "LLAMA_CACHE=/var/cache/llama-cpp-oss" ];

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

        systemd.sockets.llama-cpp-oss-proxy = {
          description = "Hermes endpoint that starts the gpt-oss-20b server on demand";
          wantedBy = [ "sockets.target" ];
          listenStreams = [ "127.0.0.1:${toString ossHermesPort}" ];
          socketConfig.Accept = false;
        };

        systemd.services.llama-cpp-oss-proxy = {
          description = "Socket-activated proxy to the gpt-oss-20b server";
          requires = [
            "llama-cpp-oss.service"
            "llama-cpp-oss-proxy.socket"
          ];
          after = [
            "llama-cpp-oss.service"
            "llama-cpp-oss-proxy.socket"
          ];
          serviceConfig = {
            # The server loads — and on first use downloads 11.3 GiB — before
            # it listens, so keep the client queued until it reports healthy.
            ExecStartPre = pkgs.writeShellScript "wait-for-llama-cpp-oss" ''
              deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 3600 ))
              while [ "$(${pkgs.coreutils}/bin/date +%s)" -lt "$deadline" ]; do
                if ${pkgs.curl}/bin/curl --silent --fail --max-time 5 \
                  "http://127.0.0.1:${toString ossServerPort}/health" >/dev/null; then
                  exit 0
                fi
                ${pkgs.coreutils}/bin/sleep 1
              done
              echo "llama-cpp-oss did not become healthy within an hour" >&2
              exit 1
            '';
            ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=300 127.0.0.1:${toString ossServerPort}";
            Type = "notify";
            TimeoutStartSec = "infinity";
            DynamicUser = true;
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

          providers.llama-cpp = {
            # The picker labels the row with this name; without it the label is
            # the provider key (`llama-cpp`).
            name = "llama.cpp (local)";
            base_url = "http://127.0.0.1:${toString hermesPort}/v1";
            model = modelAlias;
            # Matches ctx-size above, so the picker does not have to probe
            # the server for it.
            models.${modelAlias}.context_length = 65536;
            # No live /models probe: a dict-shaped `models:` still gets probed
            # by default, and these endpoints are socket-activated — listing
            # models would pull the server in (and, for the second row, start
            # an 11 GiB download and stop whichever model is running). The row
            # stays populated from `model` plus the declared ids above.
            discover_models = false;
          };

          providers.llama-cpp-oss = {
            name = "gpt-oss-20b (local)";
            base_url = "http://127.0.0.1:${toString ossHermesPort}/v1";
            model = ossAlias;
            api_mode = "chat_completions";
            # Matches ctx-size above.
            models.${ossAlias}.context_length = 131072;
            # See the note on the row above: never probe a socket-activated
            # endpoint from the picker.
            discover_models = false;
          };

          # Per-model capability patch that always beats the models.dev
          # catalog. gpt-oss-20b reasons (llama-server returns the analysis in
          # `message.reasoning_content`) and calls tools; declaring it here is
          # what offers the Thinking controls for this row instead of leaving
          # them to a catalog guess.
          model_overrides."llama-cpp-oss".${ossAlias} = {
            supports_tools = true;
            supports_reasoning = true;
            context_window = 131072;
            model_family = "gpt-oss";
          };

          # The pre-rename `providers.llamacpp` block from earlier activations
          # stays on disk (the merge cannot delete keys) and is retired here;
          # `enabled = false` hides it from the picker, /models, the runtime
          # resolver and doctor.
          providers.llamacpp.enabled = false;

          # Endpoints from the earlier LM Studio setup run nowhere on this
          # host. The provider block stays in config.yaml, disabled, and the
          # legacy list goes away: this module owns both keys from here on,
          # so endpoints added through the desktop UI do not survive an
          # activation. Declare them in this file instead.
          custom_providers = [ ];
          providers.custom.enabled = false;
        };
      };
    };
  };
}
