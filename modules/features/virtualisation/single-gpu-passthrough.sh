# This is run by libvirt as root. Do not call virsh from a libvirt hook.
# The VM must have BOTH the RX 7900 XT and its audio function as managed hostdevs.
vm=${1:-}
operation=${2:-}
phase=${3:-}
state=/run/single-gpu-passthrough-display-stopped

# Never interrupt other virtual machines.
[[ $vm == windows-gaming ]] || exit 0

gpu_path=
for device in /sys/bus/pci/devices/*; do
  if [[ $(<"$device/vendor") == 0x1002 && $(<"$device/device") == 0x744c ]]; then
    gpu_path=$device
    break
  fi
done
audio_path=${gpu_path%.*}.1

case "$operation/$phase" in
  prepare/begin)
    [[ ! -e $state ]] || { echo "Display handoff already active: $state" >&2; exit 1; }
    [[ -n $gpu_path && -d $gpu_path/iommu_group ]] || {
      echo 'RX 7900 XT not found in an IOMMU group; check BIOS virtualization/IOMMU settings.' >&2
      exit 1
    }
    [[ $(readlink -f "$gpu_path/driver" 2>/dev/null) == */amdgpu ]] || {
      echo 'RX 7900 XT is not currently bound to amdgpu.' >&2
      exit 1
    }
    [[ -e $audio_path && $(<"$audio_path/vendor") == 0x1002 && $(<"$audio_path/device") == 0xab30 && -d $audio_path/iommu_group ]] || {
      echo 'RX 7900 XT audio function missing or not in an IOMMU group.' >&2
      exit 1
    }
    audio_driver=$(readlink -f "$audio_path/driver")
    [[ -L $audio_path/driver ]] || {
      echo 'RX 7900 XT audio function has no host driver to restore.' >&2
      exit 1
    }
    audio_driver=${audio_driver##*/}
    python3 "$GPU_VM_VALIDATOR" "${gpu_path##*/}" "${audio_path##*/}" || exit 1
    # The saved XML may predate a changed PCI topology; never hand over a
    # group that now also contains a host-critical device.
    for function_path in "$gpu_path" "$audio_path"; do
      for member in "$function_path"/iommu_group/devices/*; do
        case ${member##*/} in
          "${gpu_path##*/}"|"${audio_path##*/}") ;;
          *) echo "IOMMU group of ${function_path##*/} contains unrelated ${member##*/}." >&2; exit 1 ;;
        esac
      done
    done
    # A failed preparation must not leave the host without its login screen.
    rollback() {
      if systemctl start display-manager.service; then
        rm -f "$state"
      else
        echo "Display restart failed; recovery marker retained at $state. Recover over SSH." >&2
      fi
    }
    printf '%s\n' "$audio_driver" > "$state"
    trap rollback EXIT
    systemctl stop display-manager.service
    if systemctl is-active --quiet display-manager.service; then
      echo 'Display manager is still active; aborting GPU handoff.' >&2
      exit 1
    fi
    trap - EXIT
    ;;
  release/end)
    [[ -e $state ]] || exit 0
    audio_driver=$(<"$state")
    # managed=yes returns the PCI devices to their original host drivers.
    for _ in {1..30}; do
      if [[ -n $gpu_path && $(readlink -f "$gpu_path/driver" 2>/dev/null) == */amdgpu &&
            -n $audio_driver && -e $audio_path && $(readlink -f "$audio_path/driver" 2>/dev/null) == */"$audio_driver" ]]; then
        systemctl start display-manager.service
        rm -f "$state"
        exit 0
      fi
      sleep 1
    done
    echo 'GPU or audio did not rebind to its original driver. Display remains stopped; recover over SSH.' >&2
    exit 1
    ;;
esac
