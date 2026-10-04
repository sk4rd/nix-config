import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import syslog
import time
import xml.etree.ElementTree as ET


DOMAIN = "windows-gaming"
UUID = "9ed40d76-ad6e-4080-b345-6d7d2aece0a1"
DEVICES = {
    "0000:03:00.0": ("0x1002", "0x744c", "amdgpu"),
    "0000:03:00.1": ("0x1002", "0xab30", "snd_hda_intel"),
}
SYS = Path("/sys")
STATE = Path("/run/windows-gaming-gpu")


def run(*args, check=True):
    return subprocess.run(args, check=check, text=True, capture_output=True, timeout=60)


def log(message):
    print(f"windows-gaming-gpu: {message}", file=sys.stderr, flush=True)
    syslog.openlog("windows-gaming-gpu", syslog.LOG_PID, syslog.LOG_DAEMON)
    syslog.syslog(syslog.LOG_NOTICE, message)


def driver(device):
    link = device / "driver"
    return link.resolve().name if link.exists() else None


def write(path, value):
    path.write_text(value)


def validate_xml(xml):
    root = ET.fromstring(xml)
    if root.findtext("name") != DOMAIN or root.findtext("uuid") != UUID:
        raise RuntimeError("Unexpected domain identity; refusing GPU handoff")
    addresses = set()
    for hostdev in root.findall("./devices/hostdev[@type='pci']"):
        if hostdev.get("managed") != "yes":
            raise RuntimeError("GPU functions must use libvirt managed=yes")
        address = hostdev.find("./source/address")
        addresses.add("%04x:%02x:%02x.%x" % tuple(
            int(address.get(key), 0) for key in ("domain", "bus", "slot", "function")
        ))
    if addresses != set(DEVICES):
        raise RuntimeError("Domain PCI devices do not match the desktop GPU/audio pair")
    return root


def preflight(xml):
    root = validate_xml(xml)
    for address, (vendor, product, expected_driver) in DEVICES.items():
        device = SYS / "bus/pci/devices" / address
        if (device / "vendor").read_text().strip() != vendor or (device / "device").read_text().strip() != product:
            raise RuntimeError(f"Unexpected hardware at {address}")
        if driver(device) != expected_driver:
            raise RuntimeError(f"{address} is not owned by {expected_driver}")
        group = device / "iommu_group/devices"
        if not group.exists():
            raise RuntimeError(f"IOMMU is unavailable for {address}; enable it in firmware")
        for member in group.iterdir():
            if member.name not in DEVICES and not (member / "class").read_text().startswith("0x0604"):
                raise RuntimeError(f"Unsafe IOMMU group: {address} shares it with {member.name}")
    if not (SYS / "bus/pci/devices/0000:03:00.0/reset").exists():
        raise RuntimeError("GPU has no kernel-supported reset")
    for core in range(8, 16):
        cpu = SYS / f"devices/system/cpu/cpu{core}"
        if (cpu / "topology/thread_siblings_list").read_text().strip() != f"{core},{core + 16}":
            raise RuntimeError("CPU topology changed; review the VM's vCPU pinning")
        if (cpu / "cache/index3/shared_cpu_list").read_text().strip() != "8-15,24-31":
            raise RuntimeError("CPU cache topology changed; review the VM's vCPU pinning")
    for disk in root.findall("./devices/disk/source"):
        if not Path(disk.get("file")).is_file():
            raise RuntimeError(f"Missing VM disk/media: {disk.get('file')}")
    usb_devices = list((SYS / "bus/usb/devices").glob("*/idVendor"))
    for source in root.findall("./devices/hostdev[@type='usb']/source[@startupPolicy='mandatory']"):
        vendor = int(source.find("vendor").get("id"), 0)
        product = int(source.find("product").get("id"), 0)
        matches = [p for p in usb_devices if int(p.read_text(), 16) == vendor
                   and int((p.parent / "idProduct").read_text(), 16) == product]
        if len(matches) != 1:
            raise RuntimeError(f"Expected exactly one USB input device {vendor:04x}:{product:04x}")


def graphical_sessions():
    sessions = json.loads(run("loginctl", "list-sessions", "--json=short").stdout)
    result = []
    for session in sessions:
        properties = dict(line.split("=", 1) for line in run(
            "loginctl", "show-session", str(session["session"]),
            "--property=Type", "--property=User", "--property=Remote",
        ).stdout.splitlines())
        if properties.get("Type") in ("x11", "wayland") and properties.get("Remote") == "no":
            result.append((str(session["session"]), int(properties["User"])))
    return result


def save_state(state):
    temporary = STATE / "state.tmp"
    temporary.write_text(json.dumps(state))
    temporary.replace(STATE / "state.json")


def device_nodes():
    nodes = []
    for path in (SYS / "class/drm").glob("*"):
        if (path / "device").resolve().name == "0000:03:00.0" and (Path("/dev/dri") / path.name).exists():
            nodes.append(str(Path("/dev/dri") / path.name))
    for card in (SYS / "class/sound").glob("card*"):
        if (card / "device").resolve().name == "0000:03:00.1":
            number = card.name.removeprefix("card")
            nodes.extend(str(p) for p in Path("/dev/snd").glob(f"*C{number}*"))
    return nodes


def ensure_unused():
    nodes = device_nodes()
    if nodes:
        result = run("fuser", "--", *nodes, check=False)
        if result.returncode == 0:
            raise RuntimeError(f"Processes still hold the GPU/audio devices: {result.stdout.strip()}")
        if result.returncode != 1:
            raise RuntimeError(f"Cannot check GPU users: {result.stderr.strip()}")


def restore():
    state_file = STATE / "state.json"
    if not state_file.exists():
        return
    state = json.loads(state_file.read_text())
    # release/end runs after libvirt has stopped QEMU and released managed PCI devices.
    for address, (_, _, expected_driver) in DEVICES.items():
        device = SYS / "bus/pci/devices" / address
        run("modprobe", expected_driver)
        current = driver(device)
        if current != expected_driver:
            if current not in (None, "vfio-pci"):
                raise RuntimeError(f"Refusing to detach unexpected driver {current} from {address}")
            if current:
                write(device / "driver/unbind", address)
            write(device / "driver_override", "\n")
            write(SYS / "bus/pci/drivers_probe", address)
            for _ in range(50):
                if driver(device) == expected_driver:
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError(f"Could not restore {expected_driver} on {address}; state retained for recovery")
    for console in state["consoles"]:
        path = SYS / "class/vtconsole" / console / "bind"
        if path.exists():
            write(path, "1")
    if state["display_manager"]:
        system_state = run("systemctl", "is-system-running", check=False).stdout.strip()
        if system_state != "stopping":
            run("systemctl", "start", "display-manager.service")
    state_file.unlink()
    log("Host GPU and login screen restored")


def prepare(xml):
    if (STATE / "state.json").exists():
        raise RuntimeError("A previous handoff is unfinished; run sudo windows-vm-recover first")
    preflight(xml)
    sessions = graphical_sessions()
    consoles = [p.name for p in (SYS / "class/vtconsole").iterdir()
                if "frame buffer" in (p / "name").read_text() and (p / "bind").read_text().strip() == "1"]
    active = run("systemctl", "is-active", "display-manager.service", check=False)
    if active.returncode not in (0, 3):
        raise RuntimeError("Could not determine display-manager state")
    save_state({"consoles": consoles, "display_manager": active.returncode == 0})
    try:
        log("Ending local graphical sessions and releasing the main GPU")
        run("systemctl", "stop", "display-manager.service")
        # Plasma and PipeWire user units can retain DRM/audio handles after SDDM stops.
        for uid in sorted({uid for _, uid in sessions}):
            run("systemctl", "stop", f"user@{uid}.service")
        for session, _ in sessions:
            run("loginctl", "terminate-session", session, check=False)
        run("udevadm", "settle", "--timeout=10")
        ensure_unused()
        for console in consoles:
            write(SYS / "class/vtconsole" / console / "bind", "0")
        log("GPU released; libvirt will detach and reattach the managed PCI functions")
    except Exception:
        restore()
        raise


def main(args):
    recovery = args == ["recover"]
    if not recovery and (len(args) < 3 or args[0] != DOMAIN or (args[1], args[2]) not in (
        ("prepare", "begin"), ("release", "end"),
    )):
        return 0
    if os.geteuid() != 0:
        raise RuntimeError("GPU handoff requires root")
    STATE.mkdir(mode=0o700, exist_ok=True)
    with (STATE / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if recovery:
            # Never call virsh from a libvirt hook: it can deadlock its daemon.
            active = run("virsh", "--connect", "qemu:///system", "list", "--name").stdout.splitlines()
            if DOMAIN in active:
                raise RuntimeError("The Windows VM is active; shut it down before recovering the GPU")
            restore()
        elif args[1] == "prepare":
            prepare(sys.stdin.read())
        else:
            restore()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as error:
        log(str(error))
        sys.exit(1)
