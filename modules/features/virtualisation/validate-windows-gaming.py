#!/usr/bin/env python3
"""Validate managed GPU passthrough or explicit, virtual-device-only SPICE recovery."""
from ipaddress import ip_address
import sys
import xml.etree.ElementTree as ET


RECOVERY_NAMESPACE = "urn:nix-config:windows-gaming"
RECOVERY_TAG = f"{{{RECOVERY_NAMESPACE}}}recovery"
# libvirt's own passthrough escape hatch: raw QEMU arguments and device
# overrides can add host devices or listeners the XML below never validates.
QEMU_NAMESPACE = "http://libvirt.org/schemas/domain/qemu/1.0"
QEMU_LOCAL_NAMES = {"commandline", "override"}
# Recovery is an isolated virtual diagnostic boot: nothing may reach a host
# device, host file tree or physical render node.
VIRTUAL_INPUT_TYPES = {"keyboard", "mouse", "tablet"}
HOST_BACKEND_ELEMENTS = {"filesystem", "redirdev"}
PHYSICAL_RENDER_ELEMENTS = {"gl", "rendernode", "acceleration"}
HOST_SOURCE_ATTRIBUTES = {"dev", "path", "dir"}
DISK_DEVICES = {"disk", "cdrom"}
DISK_SOURCE_ATTRIBUTES = {"file", "startupPolicy", "index"}


def local_name(tag):
    return tag.rsplit("}", 1)[-1] if isinstance(tag, str) else ""


def is_loopback(address):
    try:
        return ip_address(address).is_loopback
    except ValueError:
        return False


def domain_mode(root):
    """Validate explicit recovery before callers inspect or touch host hardware."""
    # Reserve this namespace and the recovery local name: typos must not silently
    # fall through to a normal GPU handoff, even when both PCI devices remain.
    intents = [element for element in root.iter()
               if element.tag.startswith(f"{{{RECOVERY_NAMESPACE}}}")
               or element.tag.rsplit("}", 1)[-1] == "recovery"]
    if any(key.startswith(f"{{{RECOVERY_NAMESPACE}}}") or key.rsplit("}", 1)[-1] == "recovery"
           for element in root.iter() for key in element.attrib):
        raise ValueError("malformed recovery metadata: opt-in must be an element")
    if not intents:
        return "passthrough"
    metadata = root.findall("metadata")
    if (len(intents) != 1 or len(metadata) != 1
            or intents[0] not in list(metadata[0])
            or intents[0].tag != RECOVERY_TAG
            or intents[0].attrib != {"mode": "spice-only"}
            or len(intents[0]) or (intents[0].text or "").strip()):
        raise ValueError("malformed or unknown recovery metadata")
    if (root.tag != "domain" or len(root.findall("name")) != 1
            or root.findtext("name") != "windows-gaming"):
        raise ValueError("recovery requires the same windows-gaming domain name")
    for element in root.iter():
        tag = element.tag if isinstance(element.tag, str) else ""
        if (tag.startswith(f"{{{QEMU_NAMESPACE}}}")
                or local_name(tag) in QEMU_LOCAL_NAMES
                or any(key.startswith(f"{{{QEMU_NAMESPACE}}}") for key in element.attrib)):
            raise ValueError("recovery forbids QEMU namespace extensions "
                             "(commandline, override, namespaced attributes)")
    if any(local_name(element.tag) == "hostdev" for element in root.iter()):
        raise ValueError("recovery forbids every hostdev (including PCI and USB)")
    if any(local_name(element.tag) == "interface" for element in root.iter()):
        raise ValueError("recovery forbids every interface (guest networking stays disabled)")
    for element in root.iter():
        name = local_name(element.tag)
        if name in PHYSICAL_RENDER_ELEMENTS:
            raise ValueError("recovery forbids physical render dependencies "
                             "(gl, rendernode, acceleration)")
        if name in HOST_BACKEND_ELEMENTS:
            raise ValueError(f"recovery forbids the host device backend {name}")
        if name == "input" and (element.get("type") not in VIRTUAL_INPUT_TYPES
                                or element.find("source") is not None):
            raise ValueError("recovery forbids host input backends (evdev and passthrough)")
        if name == "tpm":
            backend = element.find("backend")
            if backend is None or backend.get("type") != "emulator":
                raise ValueError("recovery requires the emulator TPM backend")
        if name == "disk":
            sources = element.findall("source")
            if (element.get("type") != "file"
                    or element.get("device", "disk") not in DISK_DEVICES
                    or any(set(source.attrib) - DISK_SOURCE_ATTRIBUTES for source in sources)
                    or any(len(source) for source in sources)):
                raise ValueError("recovery forbids non-file disks or host disk sources")
        if name == "source" and set(element.attrib) & HOST_SOURCE_ATTRIBUTES:
            raise ValueError("recovery forbids host device sources (dev, path, dir)")
    graphics = root.findall("./devices/graphics")
    if len(root.findall("devices")) != 1 or len(graphics) != 1 or graphics[0].get("type") != "spice":
        raise ValueError("recovery requires exactly one SPICE console")
    console = graphics[0]
    listens = console.findall("listen")
    addresses = [console.get("listen")] if "listen" in console.attrib else []
    if len(listens) > 1 or any(listener.get("type") != "address" for listener in listens):
        raise ValueError("recovery SPICE requires a loopback address listener")
    addresses.extend(listener.get("address", "") for listener in listens)
    if not addresses or any(not is_loopback(address) for address in addresses):
        raise ValueError("recovery SPICE must listen explicitly on loopback only")
    videos = root.findall("./devices/video")
    models = root.findall("./devices/video/model")
    if (len(videos) != 1 or len(models) != 1
            or models[0].get("type") not in {"virtio", "qxl", "vga", "bochs", "cirrus"}):
        raise ValueError("recovery requires an emulated video model")
    return "recovery"


def validate(xml, gpu, audio):
    root = ET.fromstring(xml)
    if domain_mode(root) == "recovery":
        return "recovery"
    found = set()
    for device in root.findall("./devices/hostdev"):
        if (device.get("mode"), device.get("type"), device.get("managed")) != ("subsystem", "pci", "yes"):
            continue
        address = device.find("./source/address")
        if address is not None:
            try:
                found.add("%04x:%02x:%02x.%d" % tuple(
                    int(address.get(key), 0) for key in ("domain", "bus", "slot", "function")
                ))
            except (TypeError, ValueError):
                pass
    required = {gpu, audio}
    if not required.issubset(found):
        raise ValueError(f"managed PCI hostdevs missing: {sorted(required - found)}")


if __name__ == "__main__":
    try:
        xml = sys.stdin.read()
        if sys.argv[1:] == ["--mode"]:
            # Normal mode still needs PCI-address validation after discovery.
            print(domain_mode(ET.fromstring(xml)))
        else:
            validate(xml, sys.argv[1], sys.argv[2])
    except (ET.ParseError, ValueError, IndexError) as error:
        print(f"Invalid GPU passthrough VM: {error}", file=sys.stderr)
        sys.exit(1)
