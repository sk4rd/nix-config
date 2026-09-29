{ den, ... }:

{
  # The host normally owns the GPU; libvirt detaches it only while the guest runs.
  den.aspects.single-gpu-passthrough.nixos =
    { pkgs, ... }:
    {
      virtualisation.libvirtd.hooks.qemu.single-gpu-passthrough = pkgs.writeShellApplication {
        name = "single-gpu-passthrough";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.python3
          pkgs.systemd
        ];
        text = ''
          export GPU_VM_VALIDATOR=${./validate-windows-gaming.py}
        ''
        + builtins.readFile ./single-gpu-passthrough.sh;
      };
    };
}
