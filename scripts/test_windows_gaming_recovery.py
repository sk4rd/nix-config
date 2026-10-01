import os
from pathlib import Path
import subprocess
import shutil
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

from test_gpu_hook_validator import template, validator

SCRIPT = Path(__file__).with_name("windows-gaming-recovery.py")


def structure(element):
    """Compare XML meaning, not prefixes, quote style or indentation."""
    return (element.tag, element.attrib, (element.text or "").strip(),
            [structure(child) for child in element])


class RecoveryWriterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.source = self.directory / "original.xml"
        self.output = self.directory / "recovery.xml"
        self.root = ET.fromstring(template.generate("0000:09:00.0", "0000:09:00.1",
                                                   Path("/images/windows.qcow2")))
        ET.SubElement(self.root, "uuid").text = "9ed40d76-ad6e-4080-b345-6d7d2aece0a1"
        ET.SubElement(self.root.find("os"), "nvram", template="/firmware/vars.fd").text = "/nvram/windows.fd"
        ET.SubElement(self.root.find("devices"), "input", type="keyboard", bus="ps2")
        ET.SubElement(self.root.find("devices"), "input", type="mouse", bus="ps2")
        metadata = ET.SubElement(self.root, "metadata")
        ET.SubElement(metadata, "{urn:other}note").text = "retain me"
        self.source.write_bytes(ET.tostring(self.root))

    def run_writer(self, output=None):
        return subprocess.run([sys.executable, str(SCRIPT), "--source", str(self.source),
                               "--output", str(output or self.output)],
                              env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"),
                              capture_output=True, timeout=5)

    def test_cli_creates_no_import_cache_or_other_side_files(self):
        repo = self.directory / "repo"
        script = repo / "scripts" / SCRIPT.name
        script.parent.mkdir(parents=True)
        module = repo / "modules/features/virtualisation/validate-windows-gaming.py"
        module.parent.mkdir(parents=True)
        shutil.copyfile(SCRIPT, script)
        shutil.copyfile(Path(validator.__file__), module)
        before = set(repo.rglob("*"))
        env = dict(os.environ)
        env.pop("PYTHONDONTWRITEBYTECODE", None)
        result = subprocess.run([sys.executable, str(script), "--source", str(self.source),
                                 "--output", str(self.output)], env=env, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(set(repo.rglob("*")), before)

    def test_rejects_unsaved_or_active_definition_without_output(self):
        for field in ("uuid", "active-id", "name", "graphics", "video"):
            with self.subTest(field=field):
                self.output.unlink(missing_ok=True)
                root = ET.fromstring(ET.tostring(self.root))
                if field == "uuid":
                    root.remove(root.find("uuid"))
                elif field == "active-id":
                    root.set("id", "2")
                elif field == "name":
                    root.find("name").text = "different-guest"
                else:
                    root.find("devices").remove(root.find(f"./devices/{field}"))
                self.source.write_bytes(ET.tostring(root))
                before = self.source.read_bytes()
                result = self.run_writer()
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.output.exists())
                self.assertEqual(self.source.read_bytes(), before)

    def test_output_is_exclusive_including_source_and_symlinks(self):
        before = self.source.read_bytes()
        self.output.write_text("must not overwrite")
        alias = self.directory / "alias.xml"
        alias.symlink_to(self.source)
        dangling = self.directory / "dangling.xml"
        dangling.symlink_to(self.directory / "absent.xml")
        for target in (self.output, self.source, alias, dangling):
            with self.subTest(target=target.name):
                result = self.run_writer(target)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(b"File exists", result.stderr)
        self.assertEqual(self.source.read_bytes(), before)
        self.assertEqual(self.output.read_text(), "must not overwrite")
        self.assertFalse((self.directory / "absent.xml").exists())

    def test_removes_all_interfaces_including_network_hostdev_actual(self):
        devices = self.root.find("devices")
        for kind in ("hostdev", "bridge", "user"):
            ET.SubElement(devices, "interface", type=kind)
        ET.SubElement(devices.find("interface"), "actual", type="hostdev")
        self.source.write_bytes(ET.tostring(self.root))
        before = self.source.read_bytes()
        result = self.run_writer()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertFalse(ET.fromstring(self.output.read_bytes()).findall(".//interface"))
        self.assertEqual(self.source.read_bytes(), before)

    def test_rejects_qemu_arguments_in_source_without_output(self):
        qemu = "http://libvirt.org/schemas/domain/qemu/1.0"
        self.root.append(ET.fromstring(
            f'<qemu:commandline xmlns:qemu="{qemu}"><qemu:arg value="-device"/>'
            '<qemu:arg value="vfio-pci,host=0000:03:00.0"/></qemu:commandline>'))
        self.source.write_bytes(ET.tostring(self.root))
        before = self.source.read_bytes()
        result = self.run_writer()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(b"QEMU", result.stderr)
        self.assertFalse(self.output.exists())
        self.assertEqual(self.source.read_bytes(), before)

    def test_rejects_host_backed_devices_instead_of_stripping_them(self):
        devices = self.root.find("devices")
        suspicious = (
            '<input type="evdev"><source dev="/dev/input/event3"/></input>',
            '<filesystem type="mount" accessmode="passthrough">'
            '<source dir="/home/miko"/><target dir="/host"/></filesystem>',
            '<disk type="block" device="disk"><source dev="/dev/nvme0n1"/>'
            '<target dev="vdb" bus="virtio"/></disk>',
        )
        for xml in suspicious:
            with self.subTest(device=xml):
                self.output.unlink(missing_ok=True)
                device = ET.fromstring(xml)
                devices.append(device)
                self.source.write_bytes(ET.tostring(self.root))
                before = self.source.read_bytes()
                try:
                    result = self.run_writer()
                finally:
                    devices.remove(device)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.output.exists())
                self.assertEqual(self.source.read_bytes(), before)

    def test_creates_only_recovery_xml_preserving_original_and_identity(self):
        before = self.source.read_bytes()
        result = self.run_writer()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(self.source.read_bytes(), before)
        self.assertEqual(set(self.directory.iterdir()), {self.source, self.output})
        written = ET.fromstring(self.output.read_bytes())
        self.assertEqual(validator.domain_mode(written), "recovery")
        self.assertFalse(written.findall(".//hostdev"))
        self.assertFalse(written.findall(".//interface"))
        written.find("metadata").remove(written.find(f"./metadata/{validator.RECOVERY_TAG}"))
        for device in list(self.root.find("devices")):
            if device.tag in {"hostdev", "interface"}:
                self.root.find("devices").remove(device)
        self.assertEqual(structure(written), structure(self.root))


if __name__ == "__main__":
    unittest.main()
