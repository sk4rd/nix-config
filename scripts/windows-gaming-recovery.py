#!/usr/bin/env python3
"""Write SPICE-only recovery XML from a saved inactive windows-gaming definition.

Removes every hostdev and every interface: recovery is an isolated diagnostic
boot with no guest networking; the laptop SPICE console stays available.

Offline only: never calls libvirt or modifies disks, firmware or TPM state.
"""
import argparse
import importlib.util
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

# Use the hook's exact recovery contract, not a second copy of its policy.
# Importing that policy must not create files beside the user's configuration.
sys.dont_write_bytecode = True
VALIDATOR = Path(__file__).resolve().parents[1] / "modules/features/virtualisation/validate-windows-gaming.py"
spec = importlib.util.spec_from_file_location("gpu_vm_validator", VALIDATOR)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def generate(xml):
    root = ET.fromstring(xml)
    if "id" in root.attrib or len(root.findall("uuid")) != 1 or not root.findtext("uuid"):
        raise ValueError("source must be saved inactive XML with the existing UUID")
    for parent in root.iter():
        for child in list(parent):
            if child.tag.rsplit("}", 1)[-1] in {"hostdev", "interface"}:
                parent.remove(child)
    metadata = root.find("metadata")
    if metadata is None:
        metadata = ET.SubElement(root, "metadata")
    ET.register_namespace("recovery", validator.RECOVERY_NAMESPACE)
    ET.SubElement(metadata, validator.RECOVERY_TAG, mode="spice-only")
    validator.domain_mode(root)
    return ET.tostring(root, encoding="unicode") + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="saved original inactive XML (kept unchanged)")
    parser.add_argument("--output", type=Path, required=True, help="new recovery XML file")
    args = parser.parse_args()
    try:
        xml = generate(args.source.read_bytes())
        # O_EXCL also rejects aliases and dangling symlinks; never truncate a
        # backup or previous output. Validate completely before creating a file.
        with args.output.open("x", encoding="utf-8") as output:
            output.write(xml)
    except (OSError, ET.ParseError, ValueError) as error:
        parser.error(str(error))
    print(f"Wrote {args.output}; original {args.source} retained. No VM state changed.")


if __name__ == "__main__":
    main()
