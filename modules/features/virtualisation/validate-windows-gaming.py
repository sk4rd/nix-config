#!/usr/bin/env python3
"""Reject a gaming VM that does not contain both managed PCI functions."""
import sys
import xml.etree.ElementTree as ET


def validate(xml, gpu, audio):
    root = ET.fromstring(xml)
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
        validate(sys.stdin.read(), sys.argv[1], sys.argv[2])
    except (ET.ParseError, ValueError, IndexError) as error:
        print(f"Invalid GPU passthrough VM: {error}", file=sys.stderr)
        sys.exit(1)
