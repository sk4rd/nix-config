{ ... }:

{
  sops.secrets."nas/credentials" = {
    mode = "0600";
  };
}
