"""Execute the hook with sandbox paths, never host sysfs or real systemctl."""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

from test_gpu_hook_validator import template

REPO = Path(__file__).resolve().parents[1]
FEATURE = REPO / "modules/features/virtualisation"


class HookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.state = self.directory / "state"
        self.sysfs = self.directory / "devices"
        self.sysfs.mkdir()
        self.calls = self.directory / "systemctl-calls"
        mock = self.directory / "systemctl"
        mock.write_text(f'#!/bin/sh\nprintf "%s\\n" "$*" >> {shlex.quote(str(self.calls))}\nexit 98\n')
        mock.chmod(0o755)
        loginctl = self.directory / "loginctl"
        loginctl.write_text(f'#!/bin/sh\nprintf "%s\\n" "loginctl $*" >> {shlex.quote(str(self.calls))}\nexit 98\n')
        loginctl.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.directory}:{os.environ['PATH']}",
                        GPU_VM_VALIDATOR=str(FEATURE / "validate-windows-gaming.py"))
        source = (FEATURE / "single-gpu-passthrough.sh").read_text()
        # Rewrite only literal host paths in a scratch copy; no test backdoor in
        # the root hook. Missing fake GPU files make accidental discovery fail.
        source = source.replace("/run/single-gpu-passthrough-display-stopped", str(self.state))
        source = source.replace("/sys/bus/pci/devices", str(self.sysfs))
        self.hook = self.directory / "hook"
        self.hook.write_text(f'#!{shutil.which("bash")}\nset -euo pipefail\n' + source)
        self.hook.chmod(0o755)
        self.root = ET.fromstring(template.generate("0000:09:00.0", "0000:09:00.1", Path("/images/windows.qcow2")))
        for device in list(self.root.find("devices")):
            if device.tag in {"hostdev", "interface"}:
                self.root.find("devices").remove(device)
        metadata = ET.SubElement(self.root, "metadata")
        ET.SubElement(metadata, "{urn:nix-config:windows-gaming}recovery", mode="spice-only")

    def run_hook(self, operation="prepare", phase="begin", xml=None):
        return subprocess.run([str(self.hook), "windows-gaming", operation, phase],
                              input=ET.tostring(self.root) if xml is None else xml,
                              env=self.env, capture_output=True, timeout=5)

    def assert_untouched(self):
        self.assertFalse(self.calls.exists(), "recovery must never call systemctl")
        self.assertFalse(self.state.exists(), "recovery must never create a handoff marker")
        self.assertEqual(list(self.sysfs.iterdir()), [])

    def test_recovery_rejects_stale_marker_before_reading_xml(self):
        self.state.write_text("snd_hda_intel\n")
        result = self.run_hook(xml=b"invalid XML")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"Display handoff already active", result.stderr)
        self.assertEqual(self.state.read_text(), "snd_hda_intel\n")
        self.assertFalse(self.calls.exists())
        self.assertNotIn(b"/devices/", result.stderr)

    def test_recovery_rejects_dangling_marker(self):
        self.state.symlink_to(self.directory / "absent")
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"Display handoff already active", result.stderr)
        self.assertTrue(self.state.is_symlink())
        self.assertFalse(self.calls.exists())

    def test_invalid_recovery_rejected_before_gpu_discovery(self):
        ET.SubElement(self.root.find("devices"), "hostdev", type="usb")
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"hostdev", result.stderr)
        self.assertNotIn(b"/devices/", result.stderr)
        self.assert_untouched()

    def test_recovery_interfaces_rejected_before_gpu_discovery(self):
        for kind in ("hostdev", "network", "user"):
            with self.subTest(kind=kind):
                device = ET.SubElement(self.root.find("devices"), "interface", type=kind)
                ET.SubElement(device, "actual", type="hostdev")
                result = self.run_hook()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(b"interface", result.stderr)
                self.assertNotIn(b"/devices/", result.stderr)
                self.assert_untouched()
                self.root.find("devices").remove(device)

    def test_recovery_qemu_arguments_rejected_before_gpu_discovery(self):
        qemu = "http://libvirt.org/schemas/domain/qemu/1.0"
        arguments = (
            f'<qemu:commandline xmlns:qemu="{qemu}"><qemu:arg value="-device"/>'
            '<qemu:arg value="vfio-pci,host=0000:03:00.0"/></qemu:commandline>',
            f'<qemu:commandline xmlns:qemu="{qemu}"><qemu:arg value="-object"/>'
            '<qemu:arg value="spicevmc,id=spice,addr.4=0.0.0.0"/></qemu:commandline>',
            f'<qemu:override xmlns:qemu="{qemu}"><qemu:device alias="ua-1"/></qemu:override>',
        )
        for xml in arguments:
            with self.subTest(argument=xml):
                self.root.append(ET.fromstring(xml))
                try:
                    result = self.run_hook()
                finally:
                    self.root.remove(self.root[-1])
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(b"QEMU", result.stderr)
                self.assertNotIn(b"/devices/", result.stderr)
                self.assert_untouched()

    def test_recovery_host_backed_devices_rejected_before_gpu_discovery(self):
        devices = self.root.find("devices")
        cases = (
            ("input", '<input type="evdev"><source dev="/dev/input/event3"/></input>'),
            ("disk", '<disk type="block" device="disk"><source dev="/dev/nvme0n1"/>'
                     '<target dev="vdb" bus="virtio"/></disk>'),
            ("render", '<gl enable="yes"/>'),
        )
        for expected, xml in cases:
            with self.subTest(device=xml):
                device = ET.fromstring(xml)
                parent = self.root.find("devices/graphics") if expected == "render" else devices
                parent.append(device)
                try:
                    result = self.run_hook()
                finally:
                    parent.remove(device)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected.encode(), result.stderr)
                self.assertNotIn(b"/devices/", result.stderr)
                self.assert_untouched()
        backend = self.root.find("./devices/tpm/backend")
        backend.set("type", "passthrough")
        try:
            result = self.run_hook()
        finally:
            backend.set("type", "emulator")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"TPM", result.stderr)
        self.assertNotIn(b"/devices/", result.stderr)
        self.assert_untouched()

    def test_release_without_marker_does_not_discover_gpu(self):
        result = self.run_hook("release", "end", xml=b"")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stderr, b"")
        self.assert_untouched()

    def test_normal_mode_still_validates_managed_gpu_from_stdin(self):
        self.root.remove(self.root.find("metadata"))
        for address, ident, driver in (("0000:09:00.0", "0x744c", "amdgpu"),
                                        ("0000:09:00.1", "0xab30", "snd_hda_intel")):
            device = self.sysfs / address
            device.mkdir()
            (device / "vendor").write_text("0x1002")
            (device / "device").write_text(ident)
            (device / "iommu_group").mkdir()
            (self.directory / driver).mkdir()
            (device / "driver").symlink_to(self.directory / driver)
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"managed PCI hostdevs missing", result.stderr)
        self.assertFalse(self.calls.exists())
        self.assertFalse(self.state.exists())

    def normal_setup(self, active=True):
        self.root = ET.fromstring(template.generate("0000:09:00.0", "0000:09:00.1", Path("/images/windows.qcow2")))
        self.rgb_state = Path(str(self.state) + "-openrgb")
        self.unresolved_state = Path(str(self.state) + "-unresolved")
        self.rgb_running = self.directory / "rgb-running"
        if active:
            self.rgb_running.touch()
        for address, ident, driver in (("0000:09:00.0", "0x744c", "amdgpu"),
                                        ("0000:09:00.1", "0xab30", "snd_hda_intel")):
            device = self.sysfs / address
            device.mkdir()
            (device / "vendor").write_text("0x1002")
            (device / "device").write_text(ident)
            members = device / "iommu_group/devices"
            members.mkdir(parents=True)
            (members / address).touch()
            (self.directory / driver).mkdir()
            (device / "driver").symlink_to(self.directory / driver)
        mock = self.directory / "systemctl"
        mock.write_text(f'''#!{shutil.which("bash")}
set -eu
printf '%s\\n' "$*" >> {shlex.quote(str(self.calls))}
cd {shlex.quote(str(self.directory))}
case "$*" in
  'is-active --quiet openrgb.service')
    test ! -e rgb-missing || exit 4
    test -e rgb-running ;;
  'show --property=ActiveState --value openrgb.service')
    test ! -e fail-rgb-query || exit 1
    if test -e rgb-transition; then printf 'deactivating\\n'
    elif test -e rgb-running; then printf 'active\\n'
    else printf 'inactive\\n'; fi ;;
  'stop openrgb.service')
    test ! -e fail-rgb-stop || exit 1
    test -e keep-rgb-active || rm -f rgb-running ;;
  'start openrgb.service')
    test ! -e fail-rgb-start || exit 1
    touch rgb-running ;;
  'stop display-manager.service')
    if test -e lose-audio; then rm -f devices/0000:09:00.1/driver; fi
    test ! -e fail-display-stop ;;
  'is-active --quiet display-manager.service') exit 3 ;;
  'show --property=ActiveState --value display-manager.service')
    test ! -e fail-display-query || exit 1
    if test -e display-status; then cat display-status; else printf 'inactive\\n'; fi ;;
  'start display-manager.service') exit 0 ;;
  '--user --machine='*' stop graphical-session.target')
    if test -e pending-graphical-stop; then touch pending-job; fi
    if test -e lose-gpu-on-target-stop; then rm -f devices/0000:09:00.0/driver; fi
    if test -e lose-audio-on-target-stop; then rm -f devices/0000:09:00.1/driver; fi
    test ! -e fail-graphical-stop ;;
  '--user --machine='*' show --property=ActiveState --value graphical-session.target')
    test ! -e fail-graphical-query || exit 1
    if test -e graphical-status; then cat graphical-status; else printf 'inactive\\n'; fi ;;
  *) exit 98 ;;
esac
''')
        self.sessions = self.directory / "sessions"
        self.sessions.mkdir()
        loginctl = self.directory / "loginctl"
        loginctl.write_text(f'''#!{shutil.which("bash")}
set -eu
printf '%s\\n' "loginctl $*" >> {shlex.quote(str(self.calls))}
cd {shlex.quote(str(self.directory))}
case "$1" in
  list-sessions)
    test ! -e fail-session-list || exit 1
    for session in sessions/*; do
      test -f "$session" || continue
      printf '%s 1000 ignored ignored ignored\\n' "${{session##*/}}"
    done ;;
  show-session)
    test ! -e fail-session-query || exit 1
    cat "sessions/$2" ;;
  *) exit 98 ;;
esac
''')
        loginctl.chmod(0o755)
        self.timeout_calls = self.directory / "timeout-calls"
        timer = self.directory / "timeout"
        timer.write_text(f'''#!{shutil.which("bash")}
set -eu
printf '%s\\n' "$*" >> {shlex.quote(str(self.timeout_calls))}
[[ $1 == --kill-after=5s && $2 == 30s ]] || exit 98
shift 2
cd {shlex.quote(str(self.directory))}
case "$*" in
  'systemctl stop display-manager.service') test ! -e timeout-display-stop || exit 124 ;;
  'systemctl show --property=ActiveState --value display-manager.service') test ! -e timeout-display-query || exit 124 ;;
  *' stop graphical-session.target')
    if test -e pending-graphical-stop; then "$@"; exit 124; fi
    test ! -e timeout-graphical-stop || exit 124 ;;
  *' show --property=ActiveState --value graphical-session.target') test ! -e timeout-graphical-query || exit 124 ;;
esac
exec "$@"
''')
        timer.chmod(0o755)
        sleep = self.directory / "sleep"
        sleep.write_text("#!/bin/sh\nexit 0\n")
        sleep.chmod(0o755)

    def add_session(self, session, name="alice", seat="seat0", remote="no",
                    kind="wayland", category="user", uid="1001"):
        (self.sessions / session).write_text(
            f"User={uid}\nName={name}\nSeat={seat}\nRemote={remote}\nType={kind}\nClass={category}\n")

    def test_pending_graphical_stop_blocks_retry_after_login_session_disappears(self):
        self.normal_setup()
        self.add_session("3")
        (self.directory / "pending-graphical-stop").touch()
        result = self.run_hook()
        self.assertEqual(result.returncode, 124, result.stderr.decode())
        self.assertTrue((self.directory / "pending-job").exists())
        (self.sessions / "3").unlink()
        calls = self.calls.read_text()
        retry = self.run_hook()
        self.assertNotEqual(retry.returncode, 0, "pending stop must block retry even without loginctl session")
        self.assertIn(b"Display handoff already active", retry.stderr)
        self.assertEqual(self.calls.read_text(), calls, "retry must not submit any operations")
        self.assertTrue(self.state.exists())
        self.assertTrue(self.rgb_state.exists())
        self.assertFalse(self.rgb_running.exists())
        self.assertNotIn("start ", calls)
        self.assertIn(b"--user --machine=alice@.host", result.stderr)
        self.assertIn(b"SSH", result.stderr)
        self.assertIn(b"pending jobs", result.stderr)
        release = self.run_hook("release", "end")
        self.assertNotEqual(release.returncode, 0, "release must not bypass unresolved stop guard")
        self.assertEqual(self.calls.read_text(), calls)
        self.assertTrue(self.state.exists())
        self.assertTrue((self.directory / "pending-job").exists())

    def test_graphical_user_is_stopped_after_display_without_terminating_ssh(self):
        self.normal_setup()
        self.add_session("3")
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        calls = self.calls.read_text().splitlines()
        target_stop = "--user --machine=alice@.host stop graphical-session.target"
        target_query = "--user --machine=alice@.host show --property=ActiveState --value graphical-session.target"
        self.assertIn(target_stop, calls)
        self.assertIn(target_query, calls)
        discovery = next(call for call in calls if call.startswith("loginctl show-session 3 "))
        self.assertLess(calls.index(discovery), calls.index("stop display-manager.service"))
        self.assertLess(calls.index("stop openrgb.service"), calls.index("stop display-manager.service"))
        self.assertLess(calls.index("stop display-manager.service"), calls.index(target_stop))
        self.assertLess(calls.index(target_stop), calls.index(target_query))
        self.assertFalse(any("terminate-" in call or "user@" in call for call in calls))
        result = self.run_hook("release", "end")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertNotIn("start graphical-session.target", self.calls.read_text())

    def test_graphical_discovery_deduplicates_real_local_users_only(self):
        self.normal_setup()
        self.add_session("01", name="alice", kind="x11")
        self.add_session("02", name="alice", kind="wayland")
        self.add_session("03", name="bob", uid="1002", seat="seat1", category="user-early")
        self.add_session("04", name="ssh", remote="yes")
        self.add_session("05", name="headless", seat="")
        self.add_session("06", name="manager", category="manager")
        self.add_session("07", name="sddm", category="greeter")
        self.add_session("08", name="tty", kind="tty")
        self.add_session("09", name="alice", remote="yes", seat="", kind="tty")
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        stops = [call for call in self.calls.read_text().splitlines()
                 if call.endswith(" stop graphical-session.target")]
        self.assertEqual(stops, ["--user --machine=alice@.host stop graphical-session.target",
                                 "--user --machine=bob@.host stop graphical-session.target"])

    def test_display_stop_requires_successful_explicit_inactive_query(self):
        self.normal_setup()
        self.add_session("3")
        for status in ("active", "activating", "deactivating", "reloading", "failed", "", "query-error"):
            with self.subTest(status=status):
                marker = self.directory / ("fail-display-query" if status == "query-error" else "display-status")
                marker.write_text(status)
                self.calls.unlink(missing_ok=True)
                try:
                    result = self.run_hook()
                    self.assertNotEqual(result.returncode, 0, result.stderr.decode())
                    self.assertNotIn("stop graphical-session.target", self.calls.read_text())
                    self.assertNotIn("start ", self.calls.read_text())
                    self.assertFalse(self.rgb_running.exists())
                    self.assertTrue(self.state.exists())
                    self.assertTrue(self.unresolved_state.exists())
                finally:
                    marker.unlink()
                    self.state.unlink(missing_ok=True)
                    self.rgb_state.unlink(missing_ok=True)
                    self.unresolved_state.unlink(missing_ok=True)
                    self.rgb_running.touch()

    def test_display_stop_error_or_timeout_retains_guard_without_restarts(self):
        self.normal_setup()
        self.add_session("3")
        for error in ("fail-display-stop", "timeout-display-stop", "timeout-display-query"):
            with self.subTest(error=error):
                marker = self.directory / error
                marker.touch()
                self.calls.unlink(missing_ok=True)
                try:
                    result = self.run_hook()
                    self.assertNotEqual(result.returncode, 0)
                    self.assertNotIn("start ", self.calls.read_text())
                    self.assertNotIn("--user", self.calls.read_text())
                    self.assertTrue(self.state.exists())
                    self.assertTrue(self.rgb_state.exists())
                    self.assertFalse(self.rgb_running.exists())
                    self.assertEqual(self.unresolved_state.read_text(), "systemctl stop display-manager.service\n")
                    self.assertIn(b"SSH", result.stderr)
                    self.assertIn(b"pending jobs", result.stderr)
                finally:
                    marker.unlink()
                    self.state.unlink(missing_ok=True)
                    self.rgb_state.unlink(missing_ok=True)
                    self.unresolved_state.unlink(missing_ok=True)
                    self.rgb_running.touch()

    def test_settled_graphical_stops_allow_safe_later_rollback(self):
        self.normal_setup()
        self.add_session("3")
        self.hook.write_text(self.hook.read_text().replace("    trap - EXIT", "    exit 1\n    trap - EXIT"))
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("start display-manager.service", self.calls.read_text())
        self.assertIn("start openrgb.service", self.calls.read_text())
        self.assertNotIn("start graphical-session.target", self.calls.read_text())
        self.assertTrue(self.rgb_running.exists())
        self.assertFalse(self.state.exists())
        self.assertFalse(self.rgb_state.exists())
        self.assertFalse(self.unresolved_state.exists())

    def test_orphan_unresolved_guard_blocks_prepare_and_release(self):
        unresolved = Path(str(self.state) + "-unresolved")
        for dangling in (False, True):
            with self.subTest(dangling=dangling):
                if dangling:
                    unresolved.symlink_to(self.directory / "absent")
                else:
                    unresolved.write_text("systemctl stop display-manager.service\n")
                try:
                    for operation, phase in (("prepare", "begin"), ("release", "end")):
                        result = self.run_hook(operation, phase)
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn(b"Unresolved graphical stop", result.stderr)
                        self.assertFalse(self.calls.exists())
                        self.assertTrue(unresolved.exists() or unresolved.is_symlink())
                finally:
                    unresolved.unlink()

    def test_graphical_manager_operations_are_bounded_and_timeouts_abort(self):
        self.normal_setup()
        self.add_session("3")
        for failure in ("timeout-graphical-stop", "timeout-graphical-query"):
            with self.subTest(failure=failure):
                marker = self.directory / failure
                marker.touch()
                try:
                    result = self.run_hook()
                    self.assertNotEqual(result.returncode, 0, "timed-out user manager must abort handoff")
                    self.assertFalse(self.rgb_running.exists())
                    self.assertTrue(self.state.exists())
                    self.assertTrue(self.unresolved_state.exists())
                    self.assertNotIn("start ", self.calls.read_text())
                    self.assertNotIn("start graphical-session.target", self.calls.read_text())
                    self.assertNotIn("terminate-", self.calls.read_text())
                    self.assertTrue(self.timeout_calls.exists())
                    self.assertIn("--kill-after=5s 30s systemctl --user --machine=alice@.host stop graphical-session.target",
                                  self.timeout_calls.read_text())
                finally:
                    marker.unlink()
                    self.state.unlink(missing_ok=True)
                    self.rgb_state.unlink(missing_ok=True)
                    self.unresolved_state.unlink(missing_ok=True)
                    self.rgb_running.touch()

    def test_incomplete_session_properties_or_ambiguous_user_route_abort_before_services(self):
        self.normal_setup()
        self.add_session("3")
        complete = (self.sessions / "3").read_text()
        cases = ["\n".join(line for line in complete.splitlines() if not line.startswith(key + "=")) + "\n"
                 for key in ("Name", "Seat", "Remote", "Type", "Class")]
        cases += [complete.replace("Name=alice", "Name=alice@other"),
                  complete.replace("Remote=no", "Remote=unknown")]
        for properties in cases:
            with self.subTest(properties=properties):
                (self.sessions / "3").write_text(properties)
                self.calls.unlink(missing_ok=True)
                try:
                    result = self.run_hook()
                    self.assertNotEqual(result.returncode, 0, "uncertain discovery must abort handoff")
                    self.assertNotIn("stop ", self.calls.read_text())
                    self.assertNotIn("start ", self.calls.read_text())
                    self.assertFalse(self.state.exists())
                    self.assertTrue(self.rgb_running.exists())
                finally:
                    self.state.unlink(missing_ok=True)
                    self.rgb_state.unlink(missing_ok=True)
                    self.rgb_running.touch()

    def test_no_graphical_users_still_stops_display_without_touching_user_managers(self):
        self.normal_setup()
        for greeter_only in (False, True):
            with self.subTest(greeter_only=greeter_only):
                if greeter_only:
                    self.add_session("1", name="sddm", category="greeter")
                    self.add_session("2", name="alice", seat="", remote="yes", kind="tty")
                    self.add_session("3", name="alice", seat="", category="manager", kind="unspecified")
                self.calls.unlink(missing_ok=True)
                result = self.run_hook()
                self.assertEqual(result.returncode, 0, result.stderr.decode())
                self.assertIn("stop display-manager.service", self.calls.read_text())
                self.assertNotIn("--user", self.calls.read_text())
                self.assertEqual(self.run_hook("release", "end").returncode, 0)

    def test_session_discovery_query_errors_abort_before_services(self):
        self.normal_setup()
        self.add_session("3")
        for error in ("fail-session-list", "fail-session-query"):
            with self.subTest(error=error):
                marker = self.directory / error
                marker.touch()
                self.calls.unlink(missing_ok=True)
                try:
                    result = self.run_hook()
                    self.assertNotEqual(result.returncode, 0)
                    self.assertNotIn("stop ", self.calls.read_text())
                    self.assertNotIn("start ", self.calls.read_text())
                    self.assertFalse(self.state.exists())
                    self.assertTrue(self.rgb_running.exists())
                finally:
                    marker.unlink()

    def test_graphical_stop_or_query_failure_retains_guard_without_restarts(self):
        self.normal_setup()
        self.add_session("3")
        self.add_session("4", name="bob")
        for error in ("fail-graphical-stop", "fail-graphical-query"):
            with self.subTest(error=error):
                marker = self.directory / error
                marker.touch()
                self.calls.unlink(missing_ok=True)
                try:
                    result = self.run_hook()
                    self.assertNotEqual(result.returncode, 0)
                    calls = self.calls.read_text()
                    self.assertNotIn("start ", calls)
                    self.assertNotIn("--machine=bob@.host", calls)
                    self.assertNotIn("start graphical-session.target", calls)
                    self.assertNotIn("terminate-", calls)
                    self.assertNotIn("user@", calls)
                    self.assertTrue(self.state.exists())
                    self.assertTrue(self.rgb_state.exists())
                    self.assertTrue(self.unresolved_state.exists())
                    self.assertFalse(self.rgb_running.exists())
                finally:
                    marker.unlink()
                    self.state.unlink(missing_ok=True)
                    self.rgb_state.unlink(missing_ok=True)
                    self.unresolved_state.unlink(missing_ok=True)
                    self.rgb_running.touch()

    def test_graphical_target_requires_inactive_not_transition_or_failed_state(self):
        self.normal_setup()
        self.add_session("3")
        marker = self.directory / "graphical-status"
        for status in ("active", "activating", "deactivating", "reloading", "failed", ""):
            with self.subTest(status=status):
                marker.write_text(status)
                self.calls.unlink(missing_ok=True)
                result = self.run_hook()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(b"Graphical session for alice is not inactive", result.stderr)
                self.assertTrue(self.state.exists())
                self.assertTrue(self.rgb_state.exists())
                self.assertFalse(self.rgb_running.exists())
                self.assertTrue(self.unresolved_state.exists())
                self.assertNotIn("start ", self.calls.read_text())
                self.state.unlink()
                self.rgb_state.unlink()
                self.unresolved_state.unlink()
                self.rgb_running.touch()

    def test_settled_graphical_stops_with_either_driver_unsafe_retains_markers(self):
        self.normal_setup()
        self.add_session("3")
        # Inject a later failure only in the scratch hook, after all stops settled.
        self.hook.write_text(self.hook.read_text().replace("    trap - EXIT", "    exit 1\n    trap - EXIT"))
        for function, driver in (("gpu", "amdgpu"), ("audio", "snd_hda_intel")):
            with self.subTest(function=function):
                marker = self.directory / f"lose-{function}-on-target-stop"
                marker.touch()
                self.calls.unlink(missing_ok=True)
                result = self.run_hook()
                self.assertNotEqual(result.returncode, 0)
                self.assertTrue(self.state.exists())
                self.assertTrue(self.rgb_state.exists())
                self.assertFalse(self.unresolved_state.exists())
                self.assertFalse(self.rgb_running.exists())
                self.assertNotIn("start ", self.calls.read_text())
                self.assertNotIn("terminate-", self.calls.read_text())
                marker.unlink()
                address = "0000:09:00.0" if function == "gpu" else "0000:09:00.1"
                (self.sysfs / address / "driver").symlink_to(self.directory / driver)
                self.assertEqual(self.run_hook("release", "end").returncode, 0)

    def test_other_guest_is_untouched_even_with_invalid_xml(self):
        result = subprocess.run([str(self.hook), "other-guest", "prepare", "begin"],
                                input=b"invalid XML", env=self.env, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assert_untouched()

    def test_real_timeout_bounds_a_stuck_user_bus_client(self):
        self.normal_setup()
        self.add_session("3")
        # Only this scratch hook uses a shorter bound. Real GNU timeout and a
        # sleeping fake client prove that the hook cannot wait indefinitely.
        (self.directory / "timeout").unlink()
        self.hook.write_text(self.hook.read_text().replace("--kill-after=5s 30s", "--kill-after=0.1s 0.2s"))
        mock = self.directory / "systemctl"
        mock.write_text(mock.read_text().replace(
            "test ! -e fail-graphical-stop ;;",
            f"{shlex.quote(shutil.which('sleep'))} 10 ;;"))
        result = self.run_hook()
        self.assertEqual(result.returncode, 124, result.stderr.decode())
        self.assertNotIn("start ", self.calls.read_text())
        self.assertNotIn("start graphical-session.target", self.calls.read_text())
        self.assertTrue(self.state.exists())
        self.assertTrue(self.unresolved_state.exists())

    def test_openrgb_active_handoff_restores_after_release(self):
        self.normal_setup()
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertFalse(self.rgb_running.exists(), "OpenRGB must stop before managed detach")
        self.assertEqual(self.state.read_text(), "snd_hda_intel\n")
        self.assertTrue(self.rgb_state.exists())
        self.assertEqual(self.calls.read_text().splitlines(), [
            "loginctl list-sessions --no-legend --no-pager",
            "is-active --quiet openrgb.service", "stop openrgb.service",
            "show --property=ActiveState --value openrgb.service", "stop display-manager.service",
            "show --property=ActiveState --value display-manager.service"])
        result = self.run_hook("release", "end")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertTrue(self.rgb_running.exists())
        self.assertFalse(self.state.exists())
        self.assertFalse(self.rgb_state.exists())

    def test_openrgb_safe_preparation_rollback_restores_prior_state(self):
        self.normal_setup()
        (self.directory / "fail-rgb-query").touch()
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.rgb_running.exists(), "safe rollback must restore OpenRGB")
        self.assertFalse(self.state.exists())
        self.assertFalse(self.rgb_state.exists())
        calls = self.calls.read_text().splitlines()
        self.assertNotIn("stop display-manager.service", calls)
        self.assertLess(calls.index("stop openrgb.service"), calls.index("start openrgb.service"))
        self.assertFalse(self.unresolved_state.exists())

    def test_openrgb_unsafe_rollback_retains_markers_without_restarting_services(self):
        self.normal_setup()
        (self.directory / "fail-display-stop").touch()
        (self.directory / "lose-audio").touch()
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.rgb_running.exists())
        self.assertTrue(self.state.exists())
        self.assertTrue(self.rgb_state.exists())
        self.assertNotIn("start ", self.calls.read_text())

    def test_openrgb_stale_auxiliary_marker_blocks_prepare_without_services(self):
        marker = Path(str(self.state) + "-openrgb")
        for dangling in (False, True):
            with self.subTest(dangling=dangling):
                if dangling:
                    marker.symlink_to(self.directory / "absent")
                else:
                    marker.touch()
                try:
                    result = self.run_hook()
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(b"OpenRGB handoff already active", result.stderr)
                    self.assertFalse(self.calls.exists())
                finally:
                    marker.unlink()

    def test_openrgb_transition_is_not_verified_inactive(self):
        self.normal_setup()
        (self.directory / "rgb-transition").touch()
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("stop display-manager.service", self.calls.read_text())

    def test_openrgb_inactive_or_uninstalled_is_never_started(self):
        self.normal_setup(active=False)
        for missing in (False, True):
            with self.subTest(uninstalled=missing):
                if missing:
                    (self.directory / "rgb-missing").touch()
                result = self.run_hook()
                self.assertEqual(result.returncode, 0, result.stderr.decode())
                self.assertFalse(self.rgb_state.exists())
                result = self.run_hook("release", "end")
                self.assertEqual(result.returncode, 0, result.stderr.decode())
                self.assertNotIn("start openrgb.service", self.calls.read_text())
                self.assertNotIn("stop openrgb.service", self.calls.read_text())
                self.assertFalse(self.rgb_running.exists())

    def test_openrgb_stop_failure_aborts_before_display_stop(self):
        self.normal_setup()
        (self.directory / "fail-rgb-stop").touch()
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("stop display-manager.service", self.calls.read_text())
        self.assertTrue(self.rgb_running.exists())
        self.assertFalse(self.state.exists())
        self.assertFalse(self.rgb_state.exists())

    def test_openrgb_stop_success_but_still_active_aborts(self):
        self.normal_setup()
        (self.directory / "keep-rgb-active").touch()
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"OpenRGB is not stopped", result.stderr)
        self.assertNotIn("stop display-manager.service", self.calls.read_text())

    def test_openrgb_query_failure_aborts(self):
        self.normal_setup()
        (self.directory / "fail-rgb-query").touch()
        result = self.run_hook()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("stop display-manager.service", self.calls.read_text())
        self.assertTrue(self.rgb_running.exists())

    def test_openrgb_release_waits_for_both_drivers(self):
        self.normal_setup()
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        for address, driver in (("0000:09:00.0", "amdgpu"),
                                ("0000:09:00.1", "snd_hda_intel")):
            with self.subTest(unbound=address):
                link = self.sysfs / address / "driver"
                link.unlink()
                result = self.run_hook("release", "end")
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.rgb_running.exists())
                self.assertTrue(self.state.exists())
                self.assertTrue(self.rgb_state.exists())
                self.assertNotIn("start ", self.calls.read_text())
                link.symlink_to(self.directory / driver)
        result = self.run_hook("release", "end")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertTrue(self.rgb_running.exists())

    def test_openrgb_restart_failure_retains_markers_for_retry(self):
        self.normal_setup()
        self.assertEqual(self.run_hook().returncode, 0)
        failure = self.directory / "fail-rgb-start"
        failure.touch()
        self.assertNotEqual(self.run_hook("release", "end").returncode, 0)
        self.assertTrue(self.state.exists())
        self.assertTrue(self.rgb_state.exists())
        failure.unlink()
        self.assertEqual(self.run_hook("release", "end").returncode, 0)
        self.assertFalse(self.state.exists())
        self.assertFalse(self.rgb_state.exists())

    def test_legacy_audio_only_marker_does_not_start_openrgb(self):
        self.normal_setup(active=False)
        self.state.write_text("snd_hda_intel\n")
        result = self.run_hook("release", "end")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(self.calls.read_text(), "start display-manager.service\n")
        self.assertFalse(self.state.exists())

    def test_orphan_openrgb_marker_does_not_restart_services_on_release(self):
        marker = Path(str(self.state) + "-openrgb")
        marker.touch()
        result = self.run_hook("release", "end")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertFalse(self.calls.exists())
        self.assertTrue(marker.exists())

    def test_recovery_bypasses_hardware_and_services(self):
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assert_untouched()


if __name__ == "__main__":
    unittest.main()
