#!/usr/bin/env python3
"""Generate (but never define or start) the desktop's Windows gaming VM XML."""

import argparse
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

GPU_ID = ("0x1002", "0x744c")
AUDIO_ID = ("0x1002", "0xab30")


def device_id(device):
    return tuple((device / key).read_text().strip().lower() for key in ("vendor", "device"))


def discover(sysfs):
    devices = list(sysfs.glob("*:*:*.*"))
    gpu = [d for d in devices if device_id(d) == GPU_ID]
    if len(gpu) != 1:
        raise ValueError("Expected exactly one RX 7900 XT [1002:744c] on the NixOS host")
    audio = sysfs / (gpu[0].name.rsplit(".", 1)[0] + ".1")
    if not audio.exists() or device_id(audio) != AUDIO_ID:
        raise ValueError("RX 7900 XT HDMI/DP audio [1002:ab30] missing at function 1")
    selected = {gpu[0].name, audio.name}
    for device in (gpu[0], audio):
        group = device / "iommu_group"
        if not group.exists():
            raise ValueError(f"No IOMMU group for {device.name}; enable IOMMU in firmware")
        members = {member.name for member in (group / "devices").iterdir()}
        unrelated = members - selected
        if unrelated:
            raise ValueError(f"IOMMU group of {device.name} also contains {sorted(unrelated)}; inspect isolation before passthrough")
    return gpu[0].name, audio.name


def add(parent, tag, text=None, **attrs):
    element = ET.SubElement(parent, tag, attrs)
    if text is not None:
        element.text = str(text)
    return element


def pci_address(address):
    domain, bus, slot_function = address.split(":")
    slot, function = slot_function.split(".")
    return dict(domain=f"0x{domain}", bus=f"0x{bus}", slot=f"0x{slot}", function=f"0x{function}")


def generate(gpu, audio, disk, windows_iso=None, virtio_iso=None):
    vm = ET.Element("domain", type="kvm")
    add(vm, "name", "windows-gaming")
    add(vm, "memory", 20480, unit="MiB")
    add(vm, "currentMemory", 20480, unit="MiB")
    add(vm, "vcpu", 16, placement="static")
    os = add(vm, "os", firmware="efi")
    add(os, "type", "hvm", arch="x86_64", machine="q35")
    add(vm, "features")
    features = vm.find("features")
    add(features, "acpi")
    add(features, "apic")
    hyperv = add(features, "hyperv", mode="custom")
    add(hyperv, "relaxed", state="on")
    add(hyperv, "vapic", state="on")
    add(hyperv, "spinlocks", state="on", retries="8191")
    add(vm, "cpu", mode="host-passthrough", check="none", migratable="off")
    add(vm.find("cpu"), "topology", sockets="1", cores="8", threads="2")
    add(vm, "clock", offset="localtime")
    add(vm, "on_poweroff", "destroy")
    add(vm, "on_reboot", "restart")
    add(vm, "on_crash", "destroy")
    devices = add(vm, "devices")
    storage = add(devices, "disk", type="file", device="disk")
    add(storage, "driver", name="qemu", type="qcow2", cache="none", io="native", discard="unmap")
    add(storage, "source", file=str(disk))
    add(storage, "target", dev="vda", bus="virtio")
    for target, iso in (("sda", windows_iso), ("sdb", virtio_iso)):
        if iso is not None:
            cdrom = add(devices, "disk", type="file", device="cdrom")
            add(cdrom, "driver", name="qemu", type="raw")
            add(cdrom, "source", file=str(iso))
            add(cdrom, "target", dev=target, bus="sata")
            add(cdrom, "readonly")
    add(devices, "controller", type="usb", model="qemu-xhci")
    nic = add(devices, "interface", type="network")
    add(nic, "source", network="default")
    add(nic, "model", type="virtio")
    graphics = add(devices, "graphics", type="spice", autoport="yes")
    add(graphics, "listen", type="address", address="127.0.0.1")
    video = add(devices, "video")
    add(video, "model", type="virtio", heads="1", primary="yes")
    tpm = add(devices, "tpm", model="tpm-crb")
    add(tpm, "backend", type="emulator", version="2.0")
    for address in (gpu, audio):
        hostdev = add(devices, "hostdev", mode="subsystem", type="pci", managed="yes")
        add(add(hostdev, "source"), "address", **pci_address(address))
    ET.indent(vm, space="  ")
    return ET.tostring(vm, encoding="unicode", xml_declaration=False) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sysfs", type=Path, default=Path("/sys/bus/pci/devices"))
    parser.add_argument("--disk", type=Path, default=Path("/var/lib/libvirt/images/windows-gaming.qcow2"))
    parser.add_argument("--windows-iso", type=Path)
    parser.add_argument("--virtio-iso", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if any(path is not None and not path.is_absolute() for path in
           (args.disk, args.output, args.windows_iso, args.virtio_iso)):
        parser.error("all paths must be absolute")
    try:
        gpu, audio = discover(args.sysfs)
        xml = generate(gpu, audio, args.disk, args.windows_iso, args.virtio_iso)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    args.output.write_text(xml)
    print(f"Generated {args.output}: GPU {gpu}, audio {audio}; no VM or disk was created")


if __name__ == "__main__":
    main()
