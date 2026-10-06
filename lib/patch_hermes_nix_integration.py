"""Pinned upstream compatibility patches; fail the build on source drift."""
import sys
from pathlib import Path


def replace(root, filename, old, new):
    path = root / filename
    text = path.read_text()
    if text.count(old) != 1:
        raise RuntimeError(f"Pinned Hermes source changed: {filename}")
    path.write_text(text.replace(old, new))


root = Path(sys.argv[1])
replace(root, "hermes_cli/config.py",
        '    if is_managed():\n        return format_managed_message(f"{action} {key}")\n',
        '    nix_telegram_secret = (\n'
        '        get_managed_system() in _NIX_MANAGED_SYSTEMS\n'
        '        and key in {"TELEGRAM_BOT_TOKEN", "TELEGRAM_ALLOWED_USERS"}\n'
        '    )\n'
        '    if is_managed() and not nix_telegram_secret:\n'
        '        return format_managed_message(f"{action} {key}")\n')
replace(root, "hermes_cli/_launchers.py",
        '    python = python or resolve_store_python(root) or Path(sys.executable)\n',
        '    nix_venv = (Path(sys.prefix).is_relative_to("/nix/store")\n'
        '                and sys.prefix != sys.base_prefix)\n'
        '    python = python or (Path(sys.executable) if nix_venv else\n'
        '                        resolve_store_python(root)) or Path(sys.executable)\n')
replace(root, "hermes_cli/gateway_supervised_restart.py",
        '    wait_budget = _get_restart_exit_wait_budget()\n',
        '    wait_budget = _get_restart_exit_wait_budget()\n'
        '    from hermes_cli.config import get_managed_system, _NIX_MANAGED_SYSTEMS\n'
        '    if get_managed_system() in _NIX_MANAGED_SYSTEMS:\n'
        '        from gateway.control_socket import pause_gateway_for_update\n'
        '        from gateway.status import _get_process_hermes_home\n'
        '        ack = pause_gateway_for_update(_get_process_hermes_home(), timeout=8.0)\n'
        '        if not ack or ack.get("pid") != supervised_pid or not ack.get("pausing"):\n'
        '            print("Gateway did not accept the supervised restart request")\n'
        '            sys.exit(1)\n'
        '        replacement_pid = _wait_for_supervised_gateway_replacement(\n'
        '            supervised_pid, timeout=wait_budget + SUPERVISED_REPLACEMENT_VERIFY_TIMEOUT)\n'
        '        if replacement_pid is None:\n'
        '            print("Supervisor did not relaunch the gateway after its graceful exit")\n'
        '            sys.exit(1)\n'
        '        print(f"Gateway relaunched by its supervisor (PID {replacement_pid})")\n'
        '        return\n')
replace(root, "hermes_cli/web_routers/messaging.py",
        '        with _profile_scope(effective_profile):\n'
        '            save_env_value("TELEGRAM_BOT_TOKEN", bot_token)\n'
        '            save_env_value("TELEGRAM_ALLOWED_USERS", ",".join(allowed_user_ids))\n'
        '            _write_platform_enabled("telegram", True)\n',
        '        with _profile_scope(effective_profile):\n'
        '            from hermes_cli.config import (require_env_writable, get_managed_system,\n'
        '                                           _NIX_MANAGED_SYSTEMS)\n'
        '            require_env_writable("TELEGRAM_BOT_TOKEN", "set")\n'
        '            require_env_writable("TELEGRAM_ALLOWED_USERS", "set")\n'
        '            nix_managed = get_managed_system() in _NIX_MANAGED_SYSTEMS\n'
        '            if nix_managed and not load_config().get("platforms", {}).get("telegram", {}).get("enabled"):\n'
        '                raise ValueError("Enable platforms.telegram.enabled in the Nix configuration first.")\n'
        '            save_env_value("TELEGRAM_BOT_TOKEN", bot_token)\n'
        '            save_env_value("TELEGRAM_ALLOWED_USERS", ",".join(allowed_user_ids))\n'
        '            if not nix_managed:\n'
        '                _write_platform_enabled("telegram", True)\n')
