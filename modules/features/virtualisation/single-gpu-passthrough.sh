# This is run by libvirt as root. Do not call virsh from a libvirt hook.
# Normal mode needs BOTH managed GPU functions; recovery is virtual-device-only (no hostdevs, no interfaces).
vm=${1:-}
operation=${2:-}
phase=${3:-}
state=/run/single-gpu-passthrough-display-stopped
openrgb_state=$state-openrgb
unresolved_state=$state-unresolved

unresolved_recovery() {
  echo "Unresolved graphical stop ($(cat "$unresolved_state")); services not restarted, markers retained. Recover over SSH: bounded checks must prove no pending jobs and ActiveState=inactive for the recorded unit/manager, or reboot the host. Do not blindly delete markers." >&2
}

# Never interrupt other virtual machines.
[[ $vm == windows-gaming ]] || exit 0

# Recovery is an explicit, validated mode of this same domain, not another VM.
# Check stale handoffs first; never hide an incomplete return-to-host operation.
case "$operation/$phase" in
  prepare/begin)
    [[ ! -e $state && ! -L $state ]] || { echo "Display handoff already active: $state" >&2; exit 1; }
    [[ ! -e $openrgb_state && ! -L $openrgb_state ]] || { echo "OpenRGB handoff already active: $openrgb_state" >&2; exit 1; }
    [[ ! -e $unresolved_state && ! -L $unresolved_state ]] || { unresolved_recovery; exit 1; }
    domain_xml=$(cat)
    mode=$(python3 "$GPU_VM_VALIDATOR" --mode <<< "$domain_xml") || exit 1
    case "$mode" in
      recovery) exit 0 ;;
      passthrough) ;;
      *) echo 'Unknown GPU VM validation mode.' >&2; exit 1 ;;
    esac
    ;;
  release/end)
    [[ ! -e $unresolved_state && ! -L $unresolved_state ]] || { unresolved_recovery; exit 1; }
    [[ -e $state ]] || exit 0
    ;;
  *) exit 0 ;;
esac

gpu_path=
for device in /sys/bus/pci/devices/*; do
  if [[ $(<"$device/vendor") == 0x1002 && $(<"$device/device") == 0x744c ]]; then
    gpu_path=$device
    break
  fi
done
audio_path=${gpu_path%.*}.1

# Bus lookup and unit jobs must not hold libvirt indefinitely. Timeout bounds
# the client, not the systemd job; on failure abort without allowing GPU detach.
bounded() {
  timeout --kill-after=5s 30s "$@"
}

host_drivers_bound() {
  [[ -n $gpu_path && $(readlink -f "$gpu_path/driver" 2>/dev/null) == */amdgpu &&
     -n $audio_driver && -e $audio_path && $(readlink -f "$audio_path/driver" 2>/dev/null) == */"$audio_driver" ]]
}

case "$operation/$phase" in
  prepare/begin)
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
    python3 "$GPU_VM_VALIDATOR" "${gpu_path##*/}" "${audio_path##*/}" <<< "$domain_xml" || exit 1
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
    # Snapshot local graphical owners before SDDM removes their login sessions.
    # Route to their existing user managers, never root's manager or SSH sessions.
    graphical_users=()
    sessions=$(bounded loginctl list-sessions --no-legend --no-pager) || exit 1
    while read -r session _; do
      [[ -n $session ]] || continue
      properties=$(bounded loginctl show-session "$session" --all \
        --property=Name --property=Seat --property=Remote --property=Type --property=Class) || exit 1
      name='' seat='' remote='' type='' class='' seat_seen=false
      while IFS='=' read -r key value; do
        case "$key" in
          Name) name=$value ;;
          Seat) seat=$value; seat_seen=true ;;
          Remote) remote=$value ;;
          Type) type=$value ;;
          Class) class=$value ;;
        esac
      done <<< "$properties"
      [[ -n $name && -n $type && -n $class && $seat_seen == true &&
         ( $remote == yes || $remote == no ) ]] || {
        echo "Incomplete login session properties for $session; aborting GPU handoff." >&2
        exit 1
      }
      if [[ -n $seat && $remote == no && ( $class == user || $class == user-early ) &&
            ( $type == x11 || $type == wayland ) ]]; then
        # A name containing '@' must not change the --machine routing target.
        [[ $name != *@* ]] || { echo 'Ambiguous graphical user name.' >&2; exit 1; }
        duplicate=false
        for owner in "${graphical_users[@]}"; do
          [[ $owner != "$name" ]] || duplicate=true
        done
        if [[ $duplicate == false ]]; then
          graphical_users+=("$name")
        fi
      fi
    done <<< "$sessions"
    # Restore the login screen only when every submitted graphical stop settled.
    # A timed-out client can leave a systemd job running, even after loginctl
    # loses the session. Persist the guard so release cannot bypass it either.
    rollback() {
      if [[ -e $unresolved_state || -L $unresolved_state ]]; then
        unresolved_recovery
        return 0
      fi
      if ! host_drivers_bound; then
        echo "Unsafe GPU/audio binding; services not restarted, marker retained at $state. Recover over SSH." >&2
        return 1
      fi
      if bounded systemctl start display-manager.service; then
        if [[ -e $openrgb_state ]]; then
          bounded systemctl start openrgb.service || return 1
          rm -f "$openrgb_state"
        fi
        rm -f "$state"
      else
        echo "Display restart failed; recovery marker retained at $state. Recover over SSH." >&2
      fi
    }
    printf '%s\n' "$audio_driver" > "$state"
    trap rollback EXIT
    if bounded systemctl is-active --quiet openrgb.service; then
      touch "$openrgb_state"
      bounded systemctl stop openrgb.service
    fi
    # is-active also returns false during transitions and on query errors.
    # An absent unit reports inactive; neither it nor an inactive unit is started.
    openrgb_status=$(bounded systemctl show --property=ActiveState --value openrgb.service)
    case "$openrgb_status" in
      inactive|failed) ;;
      *) echo 'OpenRGB is not stopped; aborting GPU handoff.' >&2; exit 1 ;;
    esac
    printf '%s\n' 'systemctl stop display-manager.service' > "$unresolved_state"
    bounded systemctl stop display-manager.service
    display_status=$(bounded systemctl show --property=ActiveState --value display-manager.service)
    [[ $display_status == inactive ]] || {
      echo 'Display manager is not inactive; aborting GPU handoff.' >&2
      exit 1
    }
    rm -f "$unresolved_state"
    for name in "${graphical_users[@]}"; do
      printf '%s\n' "systemctl --user --machine=$name@.host stop graphical-session.target" > "$unresolved_state"
      bounded systemctl --user --machine="$name@.host" stop graphical-session.target
      graphical_status=$(bounded systemctl --user --machine="$name@.host" \
        show --property=ActiveState --value graphical-session.target)
      [[ $graphical_status == inactive ]] || {
        echo "Graphical session for $name is not inactive; aborting GPU handoff." >&2
        exit 1
      }
      rm -f "$unresolved_state"
    done
    trap - EXIT
    ;;
  release/end)
    audio_driver=$(<"$state")
    # managed=yes returns the PCI devices to their original host drivers.
    for _ in {1..30}; do
      if host_drivers_bound; then
        bounded systemctl start display-manager.service
        if [[ -e $openrgb_state ]]; then
          bounded systemctl start openrgb.service
          rm -f "$openrgb_state"
        fi
        rm -f "$state"
        exit 0
      fi
      sleep 1
    done
    echo 'GPU or audio did not rebind to its original driver. Display remains stopped; recover over SSH.' >&2
    exit 1
    ;;
esac
