{ ... }:

{
  # Allowed ssh keys for incoming connection
  users.users."miko".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINru2QHxCuwsCc6yEtlLg4aoSI8KtuGg3SrZecZtKuCl miko@laptop"
  ];
}

