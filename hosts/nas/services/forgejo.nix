{ ... }:

{
  services.forgejo = {
    enable = true;
    stateDir = "/srv/forgejo";
    settings.server = {
      DOMAIN = "git.sk4rd.com";
      ROOT_URL = "https://git.sk4rd.com/";
      HTTP_PORT = 3000;
    };
  };
}
