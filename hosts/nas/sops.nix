{ ... }:

{
  sops = {
    secrets."nas/yubikey-pub" = {
      path = "/home/admin/.ssh/authorized_keys";
      owner = "admin";
      mode = "0600";
    };

    secrets."nas/wireguard/server_key" = {
      owner = "root";
      mode = "0400";
    };

    secrets."nas/wireguard/phone_psk" = {
      owner = "root";
      mode = "0400";
    };
    secrets."nas/wireguard/laptop_psk" = {
      owner = "root";
      mode = "0400";
    };
  };
}
