{ ... }:

{
  # Allowed ssh keys for incoming connection
  users.users."miko".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYWLqJA2cfV/Wk8W3uQPZlTe3vdP/60584HghZIlHjT miko@laptop"
  ];
}

