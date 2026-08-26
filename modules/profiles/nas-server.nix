{ den, ... }:

{
  den.aspects.nas-server.includes = [
    den.aspects.openssh-key-only
    den.aspects.nas-secrets
    den.aspects.nas-service-identities
    den.aspects.zfs-storage
    den.aspects.samba
    den.aspects.jellyfin
    den.aspects.joplin
    den.aspects.torrenting
    den.aspects.traefik-media
    den.aspects.home-assistant
  ];
}
