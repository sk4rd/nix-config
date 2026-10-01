import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

SCRIPT = Path(__file__).with_name("windows-gaming-template.py")
spec = importlib.util.spec_from_file_location("windows_gaming_template", SCRIPT)
template = importlib.util.module_from_spec(spec)
spec.loader.exec_module(template)


class TemplateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.sysfs = Path(self.temp.name) / "devices"
        self.sysfs.mkdir()
        self.group = Path(self.temp.name) / "group"
        (self.group / "devices").mkdir(parents=True)
        for address, ident in (("0000:09:00.0", "0x744c"), ("0000:09:00.1", "0xab30")):
            device = self.sysfs / address
            device.mkdir()
            (device / "vendor").write_text("0x1002\n")
            (device / "device").write_text(ident + "\n")
            (device / "iommu_group").symlink_to(self.group, target_is_directory=True)
            (self.group / "devices" / address).symlink_to(device, target_is_directory=True)

    def test_gpu_and_audio_are_managed_and_guest_matches_hook(self):
        gpu, audio = template.discover(self.sysfs)
        root = ET.fromstring(template.generate(gpu, audio, Path("/var/lib/libvirt/images/windows-gaming.qcow2")))
        self.assertEqual(root.findtext("name"), "windows-gaming")
        self.assertEqual(root.findtext("memory"), "20480")
        self.assertEqual(root.findtext("vcpu"), "16")
        self.assertEqual(root.find("os").get("firmware"), "efi")
        self.assertEqual(root.find("cpu").get("mode"), "host-passthrough")
        hostdevs = root.findall("./devices/hostdev[@type='pci']")
        self.assertEqual(len(hostdevs), 2)
        self.assertTrue(all(dev.get("managed") == "yes" for dev in hostdevs))
        self.assertEqual([dev.find("./source/address").get("function") for dev in hostdevs], ["0x0", "0x1"])
        self.assertEqual(root.find("./devices/disk/driver").get("discard"), "unmap")
        self.assertEqual(root.find("./devices/tpm/backend").get("version"), "2.0")

    def test_passes_only_mouse_and_keyboard_as_whole_usb_devices(self):
        root = ET.fromstring(template.generate("0000:09:00.0", "0000:09:00.1",
                                               Path("/images/windows.qcow2")))
        devices = root.findall("./devices/hostdev[@type='usb']")
        ids = [(dev.find("./source/vendor").get("id"),
                dev.find("./source/product").get("id")) for dev in devices]
        self.assertEqual(ids, [("0x1532", "0x00c1"), ("0x6b62", "0x6869")])
        self.assertTrue(all(dev.get("mode") == "subsystem" for dev in devices))
        self.assertTrue(all(dev.find("source").get("startupPolicy") == "optional"
                            for dev in devices))
        self.assertTrue(all(dev.find("./source/address") is None for dev in devices))

    def test_refuses_unrelated_iommu_group_member(self):
        (self.group / "devices" / "0000:09:01.0").symlink_to(self.sysfs / "0000:09:00.0")
        with self.assertRaisesRegex(ValueError, "also contains"):
            template.discover(self.sysfs)

    def test_refuses_wrong_audio(self):
        (self.sysfs / "0000:09:00.1" / "device").write_text("0xffff")
        with self.assertRaisesRegex(ValueError, "audio"):
            template.discover(self.sysfs)

    def test_optional_install_media(self):
        root = ET.fromstring(template.generate("0000:09:00.0", "0000:09:00.1",
                                               Path("/images/windows.qcow2"),
                                               Path("/isos/windows.iso"), Path("/isos/virtio.iso")))
        self.assertEqual(len(root.findall("./devices/disk")), 3)
        self.assertEqual(len(root.findall("./devices/disk[@device='cdrom']")), 2)


if __name__ == "__main__":
    unittest.main()
