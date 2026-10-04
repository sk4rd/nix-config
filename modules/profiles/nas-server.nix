{ den, ... }:

{
  den.aspects.nas-server.includes = [
    den.aspects.openssh-key-only
    den.aspects.nas-service-identities
    den.aspects.zfs-storage
    den.aspects.samba
    den.aspects.jellyfin
    den.aspects.seerr
    den.aspects.media-indexer-relay
    den.aspects.silverbullet
    den.aspects.neon-flux-theme
    den.aspects.prowlarr
    den.aspects.torrenting
    den.aspects.home-assistant
    den.aspects.dashboard
    den.aspects.searxng

  ];
}
