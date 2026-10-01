import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

HERE = Path(__file__).parent


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, HERE / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


template = load("windows-gaming-template.py", "template")
validator = load("../modules/features/virtualisation/validate-windows-gaming.py", "validator")


class ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.gpu = "0000:09:00.0"
        self.audio = "0000:09:00.1"
        self.root = ET.fromstring(template.generate(self.gpu, self.audio, Path("/images/windows.qcow2")))

    def check(self):
        validator.validate(ET.tostring(self.root), self.gpu, self.audio)

    def test_valid_template(self):
        self.check()

    def recovery(self):
        metadata = ET.SubElement(self.root, "metadata")
        ET.SubElement(metadata, "{urn:nix-config:windows-gaming}recovery", mode="spice-only")
        devices = self.root.find("devices")
        for device in list(devices):
            if device.tag in {"hostdev", "interface"}:
                devices.remove(device)

    def test_explicit_recovery_without_hostdevs(self):
        self.recovery()
        self.assertEqual(validator.validate(ET.tostring(self.root), self.gpu, self.audio), "recovery")

    def test_recovery_rejects_every_interface(self):
        self.recovery()
        interfaces = (
            '<interface type="hostdev" managed="yes"><source><address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/></source></interface>',
            '<interface type="network"><source network="hostdev-pool"/></interface>',
            '<interface type="network"><source network="default"/><actual type="hostdev"><source><address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/></source></actual></interface>',
            '<interface type="bridge"><source bridge="br0"/></interface>',
            '<interface type="user"/>',
        )
        for xml in interfaces:
            with self.subTest(xml=xml):
                device = ET.fromstring(xml)
                self.root.find("devices").append(device)
                try:
                    with self.assertRaisesRegex(ValueError, "interface"):
                        self.check()
                finally:
                    self.root.find("devices").remove(device)

    def test_recovery_rejects_qemu_namespace_extensions(self):
        self.recovery()
        qemu = "http://libvirt.org/schemas/domain/qemu/1.0"
        extensions = (
            f'<qemu:commandline xmlns:qemu="{qemu}"><qemu:arg value="-device"/>'
            '<qemu:arg value="vfio-pci,host=0000:03:00.0"/></qemu:commandline>',
            f'<qemu:override xmlns:qemu="{qemu}"><qemu:device alias="ua-1"><qemu:frontend/></qemu:device></qemu:override>',
            f'<qemu:spice-listen xmlns:qemu="{qemu}"/>',
            f'<commandline xmlns="{qemu}"><arg value="-object"/><arg value="spicevmc,id=spice,addr.4=127.0.0.1"/></commandline>',
            '<commandline><arg value="-netdev"/></commandline>',
        )
        for xml in extensions:
            with self.subTest(extension=xml):
                self.root.append(ET.fromstring(xml))
                try:
                    with self.assertRaisesRegex(ValueError, "QEMU"):
                        self.check()
                finally:
                    self.root.remove(self.root[-1])
        attribute = f"{{{qemu}}}cmdline"
        self.root.find("./devices/video").set(attribute, "-device vfio-pci")
        try:
            with self.assertRaisesRegex(ValueError, "QEMU"):
                self.check()
        finally:
            del self.root.find("./devices/video").attrib[attribute]

    def test_recovery_rejects_any_remaining_hostdev(self):
        self.recovery()
        for kind in ("pci", "usb", "mdev", "unknown"):
            with self.subTest(kind=kind):
                device = ET.SubElement(self.root.find("devices"), "hostdev", type=kind)
                with self.assertRaisesRegex(ValueError, "hostdev"):
                    self.check()
                self.root.find("devices").remove(device)

    def test_recovery_rejects_host_device_input_backends(self):
        self.recovery()
        devices = self.root.find("devices")
        inputs = (
            '<input type="evdev"><source dev="/dev/input/event3"/></input>',
            '<input type="passthrough" bus="virtio"/>',
            '<input type="keyboard" bus="usb"><source dev="/dev/input/event2"/></input>',
        )
        for xml in inputs:
            with self.subTest(input=xml):
                device = ET.fromstring(xml)
                devices.append(device)
                try:
                    with self.assertRaisesRegex(ValueError, "input"):
                        self.check()
                finally:
                    devices.remove(device)

    def test_recovery_requires_the_emulator_tpm_backend(self):
        self.recovery()
        self.check()
        tpm = self.root.find("./devices/tpm")
        backend = tpm.find("backend")
        backup = ET.fromstring(ET.tostring(backend))
        try:
            for kind in ("passthrough", "unknown", None):
                with self.subTest(backend=kind):
                    if kind is None:
                        tpm.remove(backend)
                    else:
                        backend.set("type", kind)
                    with self.assertRaisesRegex(ValueError, "TPM"):
                        self.check()
                    if kind is None:
                        tpm.append(backend)
                    else:
                        backend.set("type", "emulator")
        finally:
            tpm[:] = [backup]
        self.check()

    def test_recovery_rejects_physical_render_dependencies(self):
        self.recovery()
        dependencies = (
            ("./devices/graphics", '<gl enable="yes"/>'),
            ("./devices/graphics", '<rendernode path="/dev/dri/renderD128"/>'),
            ("./devices/video", '<acceleration accel3d="yes"/>'),
        )
        for path, xml in dependencies:
            with self.subTest(dependency=xml):
                parent = self.root.find(path)
                child = ET.fromstring(xml)
                parent.append(child)
                try:
                    with self.assertRaisesRegex(ValueError, "render"):
                        self.check()
                finally:
                    parent.remove(child)

    def test_recovery_rejects_non_file_disks_and_host_disk_sources(self):
        self.recovery()
        devices = self.root.find("devices")
        disks = (
            '<disk type="block" device="disk"><source dev="/dev/nvme0n1"/><target dev="vdb" bus="virtio"/></disk>',
            '<disk type="network" device="disk"><source protocol="iscsi" name="iqn.2024-01.example:disk"/><target dev="vdb" bus="virtio"/></disk>',
            '<disk type="volume" device="disk"><source pool="images" volume="windows"/><target dev="vdb" bus="virtio"/></disk>',
            '<disk type="file" device="lun"><source file="/images/mapped.img"/><target dev="vdb" bus="scsi"/></disk>',
            '<disk type="file" device="disk"><source file="/images/peripheral.qcow2"/>'
            '<source dev="/dev/nvme0n1"/><target dev="vdb" bus="virtio"/></disk>',
            '<disk type="file" device="disk"><source file="/images/guest.qcow2" dir="/mnt"/>'
            '<target dev="vdb" bus="virtio"/></disk>',
        )
        for xml in disks:
            with self.subTest(disk=xml):
                disk = ET.fromstring(xml)
                devices.append(disk)
                try:
                    with self.assertRaisesRegex(ValueError, "disk"):
                        self.check()
                finally:
                    devices.remove(disk)

    def test_recovery_rejects_other_host_device_backends(self):
        self.recovery()
        devices = self.root.find("devices")
        backends = (
            '<filesystem type="mount" accessmode="passthrough">'
            '<source dir="/home/miko"/><target dir="/host"/></filesystem>',
            '<redirdev bus="usb" type="tcp"><source host="192.0.2.1" port="4000"/></redirdev>',
            '<serial type="dev"><source path="/dev/ttyS0"/><target port="1"/></serial>',
            '<channel type="unix"><source mode="bind" path="/run/host.sock"/>'
            '<target type="virtio" name="org.example.socket"/></channel>',
            '<smartcard mode="passthrough"><source path="/dev/smartcard0"/></smartcard>',
        )
        for xml in backends:
            with self.subTest(backend=xml):
                backend = ET.fromstring(xml)
                devices.append(backend)
                try:
                    with self.assertRaisesRegex(ValueError, "host device"):
                        self.check()
                finally:
                    devices.remove(backend)

    def test_recovery_accepts_saved_layout_with_identity_devices(self):
        """Guard against over-restriction: the saved guest's own device layout."""
        self.recovery()
        devices = self.root.find("devices")
        for xml in (
            '<emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>',
            '<controller type="sata" index="0"><address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/></controller>',
            '<controller type="pci" index="0" model="pcie-root"/>',
            '<audio id="1" type="spice"/>',
            '<watchdog model="itco" action="reset"/>',
            '<memballoon model="virtio"><address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/></memballoon>',
        ):
            devices.append(ET.fromstring(xml))
        ET.SubElement(self.root.find("./devices/tpm/backend"), "profile", name="default-v1")
        nvram = ET.SubElement(self.root.find("os"), "nvram", template="/run/libvirt/nix-ovmf/edk2-i386-vars.fd")
        nvram.text = "/var/lib/libvirt/qemu/nvram/windows-gaming_VARS.fd"
        self.check()

    def test_rejects_malformed_or_unknown_recovery_intent_even_with_gpu(self):
        intents = (
            '<recovery xmlns="urn:nix-config:windows-gaming"/>',
            '<recovery xmlns="urn:nix-config:windows-gaming" mode="typo"/>',
            '<recovery xmlns="urn:nix-config:windows-gaming" mode="spice-only" extra="yes"/>',
            '<recovery xmlns="urn:nix-config:windows-gaming" mode="spice-only">yes</recovery>',
            '<recovery xmlns="urn:nix-config:windows-gaming" mode="spice-only"><extra/></recovery>',
            '<unknown xmlns="urn:nix-config:windows-gaming"/>',
            '<recovery mode="spice-only"/>',
            '<recovery xmlns="urn:wrong" mode="spice-only"/>',
            '<wrapper><recovery xmlns="urn:nix-config:windows-gaming" mode="spice-only"/></wrapper>',
            '<recovery xmlns="urn:nix-config:windows-gaming" mode="spice-only"/>' * 2,
        )
        for intent in intents:
            with self.subTest(intent=intent):
                metadata = ET.fromstring(f"<metadata>{intent}</metadata>")
                self.root.append(metadata)
                try:
                    with self.assertRaisesRegex(ValueError, "recovery metadata"):
                        self.check()
                finally:
                    self.root.remove(metadata)

    def test_recovery_intent_as_attribute_is_not_silently_ignored(self):
        self.root.set("{urn:nix-config:windows-gaming}recovery", "spice-only")
        with self.assertRaisesRegex(ValueError, "recovery metadata"):
            self.check()

    def test_recovery_requires_same_domain_name(self):
        self.recovery()
        self.root.find("name").text = "windows-recovery"
        with self.assertRaisesRegex(ValueError, "windows-gaming"):
            self.check()

    def test_recovery_requires_loopback_spice_and_emulated_video(self):
        self.recovery()
        devices = self.root.find("devices")
        spice = devices.find("graphics")
        video = devices.find("video")
        devices.remove(spice)
        devices.remove(video)
        invalid = (
            '',
            '<graphics type="vnc" listen="127.0.0.1"/>',
            '<graphics type="spice"/>',
            '<graphics type="spice" listen="0.0.0.0"/>',
            '<graphics type="spice" listen="localhost"/>',
            '<graphics type="spice"><listen type="network" network="default"/></graphics>',
            '<graphics type="spice"><listen type="address" address="::"/></graphics>',
            '<graphics type="spice" listen="0.0.0.0"><listen type="address" address="127.0.0.1"/></graphics>',
            '<graphics type="spice"><listen type="address" address="127.0.0.1"/><listen type="address" address="192.0.2.1"/></graphics>',
            '<graphics type="spice" listen="127.0.0.1"/><graphics type="vnc" listen="0.0.0.0"/>',
        )
        for console in invalid:
            with self.subTest(console=console):
                root = ET.fromstring(ET.tostring(self.root))
                target = root.find("devices")
                target.append(ET.fromstring(ET.tostring(video)))
                target.extend(ET.fromstring(f"<wrapper>{console}</wrapper>"))
                with self.assertRaisesRegex(ValueError, "SPICE|loopback"):
                    validator.validate(ET.tostring(root), self.gpu, self.audio)
        devices.append(spice)
        for model in (None, "none", "unknown"):
            with self.subTest(model=model):
                root = ET.fromstring(ET.tostring(self.root))
                if model is not None:
                    ET.SubElement(ET.SubElement(root.find("devices"), "video"), "model", type=model)
                with self.assertRaisesRegex(ValueError, "video"):
                    validator.validate(ET.tostring(root), self.gpu, self.audio)

    def test_recovery_accepts_ipv6_loopback(self):
        self.recovery()
        self.root.find("./devices/graphics/listen").set("address", "::1")
        self.check()

    def test_without_opt_in_missing_gpu_still_fails(self):
        self.recovery()
        self.root.remove(self.root.find("metadata"))
        with self.assertRaisesRegex(ValueError, "managed PCI hostdevs missing"):
            self.check()

    def test_missing_audio(self):
        self.root.find("devices").remove(self.root.findall("./devices/hostdev")[1])
        with self.assertRaisesRegex(ValueError, "managed PCI hostdevs missing"):
            self.check()

    def test_unmanaged_gpu(self):
        self.root.findall("./devices/hostdev")[0].set("managed", "no")
        with self.assertRaisesRegex(ValueError, "managed PCI hostdevs missing"):
            self.check()


if __name__ == "__main__":
    unittest.main()
