import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock


HERE = Path(__file__).parent
SPEC = importlib.util.spec_from_file_location("gpu_hook", HERE / "gpu-hook.py")
hook = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(hook)
DOMAIN_XML = (HERE / "domain.xml").read_text()


def result(stdout="", returncode=0, stderr=""):
    return subprocess.CompletedProcess([], returncode, stdout, stderr)


class HookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.sys = self.root / "sys"
        self.state = self.root / "state"
        self.sys.mkdir()
        self.state.mkdir()
        self.sys_patch = mock.patch.object(hook, "SYS", self.sys)
        self.state_patch = mock.patch.object(hook, "STATE", self.state)
        self.sys_patch.start()
        self.state_patch.start()
        self.addCleanup(self.sys_patch.stop)
        self.addCleanup(self.state_patch.stop)
        self.addCleanup(self.temp.cleanup)

    def create_preflight_tree(self, xml=DOMAIN_XML):
        import shutil
        shutil.rmtree(self.sys)
        self.sys.mkdir()
        pci = self.sys / "bus/pci/devices"
        for address, (vendor, product, bound_driver) in hook.DEVICES.items():
            device = pci / address
            device.mkdir(parents=True, exist_ok=True)
            (device / "vendor").write_text(vendor)
            (device / "device").write_text(product)
            driver = self.sys / "bus/pci/drivers" / bound_driver
            driver.mkdir(parents=True, exist_ok=True)
            (device / "driver").symlink_to(driver)
            group = device / "iommu_group/devices"
            group.mkdir(parents=True)
            (group / address).symlink_to(device)
            (device / "class").write_text("0x030000")
        (pci / "0000:03:00.0/reset").touch()
        for core in range(8, 16):
            cpu = self.sys / f"devices/system/cpu/cpu{core}"
            (cpu / "topology").mkdir(parents=True)
            (cpu / "topology/thread_siblings_list").write_text(f"{core},{core + 16}")
            (cpu / "cache/index3").mkdir(parents=True)
            (cpu / "cache/index3/shared_cpu_list").write_text("8-15,24-31")
        usb = self.sys / "bus/usb/devices"
        for index, (vendor, product) in enumerate((("6b62", "6869"), ("1532", "00c1"))):
            device = usb / f"1-{index + 1}"
            device.mkdir(parents=True)
            (device / "idVendor").write_text(vendor)
            (device / "idProduct").write_text(product)
        console = self.sys / "class/vtconsole/vtcon0"
        console.mkdir(parents=True)
        (console / "name").write_text("frame buffer device")
        (console / "bind").write_text("1")
        # Replace domain media paths with isolated temporary files.
        import xml.etree.ElementTree as ET
        root = ET.fromstring(xml)
        for index, source in enumerate(root.findall("./devices/disk/source")):
            media = self.root / f"media-{index}"
            media.touch()
            source.set("file", str(media))
        return ET.tostring(root, encoding="unicode")

    def test_guest_identity_profile_enables_physical_radeon_outputs(self):
        root = hook.validate_xml(DOMAIN_XML)
        self.assertEqual(
            [element.attrib for element in root.findall("./features/hyperv/vendor_id")],
            [{"state": "on", "value": "0123456789ab"}],
        )
        self.assertEqual(
            [element.attrib for element in root.findall("./features/kvm/hidden")],
            [{"state": "on"}],
        )

    def test_gpu_rom_bar_disabled_without_external_rom(self):
        root = hook.validate_xml(DOMAIN_XML)
        devices = root.findall("./devices/hostdev[@type='pci']")
        gpu = next(device for device in devices if device.find("./source/address").get("function") == "0x0")
        audio = next(device for device in devices if device.find("./source/address").get("function") == "0x1")
        self.assertEqual([element.attrib for element in gpu.findall("rom")], [{"bar": "off"}])
        self.assertIsNone(audio.find("rom"))

    def test_xml_identity_managed_and_exact_pci_pair(self):
        self.assertEqual(hook.validate_xml(DOMAIN_XML).findtext("name"), hook.DOMAIN)
        for changed in (
            DOMAIN_XML.replace(hook.UUID, "00000000-0000-0000-0000-000000000000"),
            DOMAIN_XML.replace('managed="yes"', 'managed="no"', 1),
            DOMAIN_XML.replace('function="0x1"', 'function="0x2"'),
        ):
            with self.subTest(changed=changed[-100:]), self.assertRaises(RuntimeError):
                hook.validate_xml(changed)

    def test_preflight_valid_fixture(self):
        xml = self.create_preflight_tree()
        with mock.patch.object(hook, "run"):
            hook.preflight(xml)

    def test_preflight_rejects_iommu_hardware_and_topology(self):
        xml = self.create_preflight_tree()
        import shutil
        shutil.rmtree(self.sys / "bus/pci/devices/0000:03:00.0/iommu_group")
        with self.assertRaisesRegex(RuntimeError, "IOMMU"):
            hook.preflight(xml)
        self.create_preflight_tree()
        (self.sys / "bus/pci/devices/0000:03:00.0/vendor").write_text("0xffff")
        with self.assertRaisesRegex(RuntimeError, "Unexpected hardware"):
            hook.preflight(xml)
        self.create_preflight_tree()
        (self.sys / "devices/system/cpu/cpu8/topology/thread_siblings_list").write_text("8")
        with self.assertRaisesRegex(RuntimeError, "CPU topology"):
            hook.preflight(xml)

    def test_preflight_rejects_unsafe_group_and_missing_input(self):
        xml = self.create_preflight_tree()
        device = self.sys / "bus/pci/devices/0000:03:00.0"
        extra = self.sys / "bus/pci/devices/0000:03:00.2"
        extra.mkdir()
        (extra / "class").write_text("0x020000")
        (device / "iommu_group/devices/0000:03:00.2").symlink_to(extra)
        with self.assertRaisesRegex(RuntimeError, "Unsafe IOMMU group"):
            hook.preflight(xml)

        self.create_preflight_tree()
        usb = self.sys / "bus/usb/devices/1-1"
        (usb / "idVendor").write_text("ffff")
        (usb / "idProduct").write_text("eeee")
        with self.assertRaisesRegex(RuntimeError, "USB input"):
            hook.preflight(xml)

    def test_prepare_stops_sessions_and_user_units_and_unbinds_consoles(self):
        xml = self.create_preflight_tree()
        calls = []
        def run(*args, **kwargs):
            calls.append(args)
            if args[:2] == ("systemctl", "is-active"):
                return result(returncode=0)
            return result()
        with mock.patch.object(hook, "preflight"), mock.patch.object(hook, "graphical_sessions", return_value=[("3", 1000), ("4", 1000), ("5", 1001)]), mock.patch.object(hook, "run", side_effect=run), mock.patch.object(hook, "ensure_unused"), mock.patch.object(hook, "log"):
            hook.prepare(xml)
        self.assertIn(("systemctl", "stop", "user@1000.service"), calls)
        self.assertIn(("systemctl", "stop", "user@1001.service"), calls)
        self.assertIn(("loginctl", "terminate-session", "3"), calls)
        self.assertEqual((self.sys / "class/vtconsole/vtcon0/bind").read_text(), "0")
        self.assertTrue((self.state / "state.json").exists())

    def test_prepare_partial_failure_restores_state(self):
        xml = self.create_preflight_tree()
        calls = []
        def run(*args, **kwargs):
            calls.append(args)
            if args[:2] == ("systemctl", "is-active"):
                return result(returncode=0)
            if args[:2] == ("systemctl", "stop"):
                raise RuntimeError("stop failed")
            return result()
        with mock.patch.object(hook, "preflight"), mock.patch.object(hook, "graphical_sessions", return_value=[]), mock.patch.object(hook, "run", side_effect=run), mock.patch.object(hook, "restore") as restore, mock.patch.object(hook, "log"):
            with self.assertRaisesRegex(RuntimeError, "stop failed"):
                hook.prepare(xml)
        restore.assert_called_once_with()

    def write_state(self, **values):
        state = {"consoles": [], "display_manager": False}
        state.update(values)
        (self.state / "state.json").write_text(json.dumps(state))

    def test_release_normal_and_idempotent_failed_start_cleanup(self):
        devices = self.sys / "bus/pci/devices"
        for address, (_, _, bound) in hook.DEVICES.items():
            device = devices / address
            device.mkdir(parents=True)
            target = self.sys / "bus/pci/drivers" / bound
            target.mkdir(parents=True, exist_ok=True)
            (device / "driver").symlink_to(target)
        self.write_state(display_manager=True)
        with mock.patch.object(hook, "run") as run, mock.patch.object(hook, "log"):
            hook.restore()
            self.assertFalse((self.state / "state.json").exists())
            hook.restore()
        self.assertEqual(run.call_args_list[-1].args, ("systemctl", "start", "display-manager.service"))

    def test_release_during_host_shutdown_does_not_restart_display_manager(self):
        self.create_preflight_tree()
        self.write_state(display_manager=True)
        calls = []
        def run(*args, **kwargs):
            calls.append(args)
            return result("stopping\n" if args == ("systemctl", "is-system-running") else "")
        with mock.patch.object(hook, "run", side_effect=run), mock.patch.object(hook, "log"):
            hook.restore()
        self.assertNotIn(("systemctl", "start", "display-manager.service"), calls)
        self.assertFalse((self.state / "state.json").exists())

    def test_libvirt_hook_dispatches_prepare_and_failed_start_release(self):
        import io
        with mock.patch.object(hook.os, "geteuid", return_value=0), mock.patch.object(hook.sys, "stdin", io.StringIO(DOMAIN_XML)), mock.patch.object(hook, "prepare") as prepare, mock.patch.object(hook, "restore") as restore:
            self.assertEqual(hook.main([hook.DOMAIN, "prepare", "begin", "-"]), 0)
            prepare.assert_called_once_with(DOMAIN_XML)
            restore.assert_not_called()
            self.assertEqual(hook.main([hook.DOMAIN, "release", "end", "failed"]), 0)
            restore.assert_called_once_with()

    def test_handoff_messages_are_logged_to_stderr_and_syslog(self):
        import io
        output = io.StringIO()
        with mock.patch.object(hook.sys, "stderr", output), mock.patch.object(hook.syslog, "openlog") as openlog, mock.patch.object(hook.syslog, "syslog") as syslog:
            hook.log("GPU released")
        self.assertIn("windows-gaming-gpu: GPU released", output.getvalue())
        openlog.assert_called_once_with("windows-gaming-gpu", hook.syslog.LOG_PID, hook.syslog.LOG_DAEMON)
        syslog.assert_called_once_with(hook.syslog.LOG_NOTICE, "GPU released")

    def test_recovery_refuses_active_vm_and_unrelated_hook_does_nothing(self):
        with mock.patch.object(hook.os, "geteuid", return_value=0), mock.patch.object(hook, "run", return_value=result("windows-gaming\n")), mock.patch.object(hook, "restore") as restore:
            with self.assertRaisesRegex(RuntimeError, "VM is active"):
                hook.main(["recover"])
            restore.assert_not_called()
        with mock.patch.object(hook.os, "geteuid", side_effect=AssertionError("unexpected host access")):
            self.assertEqual(hook.main(["other-domain", "prepare", "begin"]), 0)

    def test_restore_refuses_unexpected_driver_and_retains_state(self):
        self.write_state()
        for address in hook.DEVICES:
            device = self.sys / "bus/pci/devices" / address
            device.mkdir(parents=True)
            driver = self.sys / "bus/pci/drivers/unexpected"
            driver.mkdir(parents=True, exist_ok=True)
            (device / "driver").symlink_to(driver)
        with mock.patch.object(hook, "run"), self.assertRaisesRegex(RuntimeError, "unexpected driver"):
            hook.restore()
        self.assertTrue((self.state / "state.json").exists())

    def test_restore_failure_retains_state(self):
        self.write_state()
        for address in hook.DEVICES:
            (self.sys / "bus/pci/devices" / address).mkdir(parents=True)
        with mock.patch.object(hook, "run"), mock.patch.object(hook, "driver", return_value=None), mock.patch.object(hook, "write"), mock.patch.object(hook.time, "sleep"), self.assertRaisesRegex(RuntimeError, "state retained"):
            hook.restore()
        self.assertTrue((self.state / "state.json").exists())


if __name__ == "__main__":
    unittest.main()
