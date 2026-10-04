{ den, ... }:

let
  whenPresent =
    aspect: themes: den.lib.policy.when ({ hasAspect, ... }: hasAspect aspect) { includes = themes; };

  userThemes = [
    (whenPresent den.aspects.plasma [
      den.aspects.plasma-neon-flux-theme
      den.aspects.konsole-neon-flux-theme
      den.aspects.wallpaper-neon-flux-theme
      den.aspects.lockscreen-neon-flux-theme
    ])
    (whenPresent den.aspects.firefox [ den.aspects.firefox-neon-flux-theme ])
    (whenPresent den.aspects.zed [ den.aspects.zed-neon-flux-theme ])
  ];
in
{
  # Theme existing capabilities without pulling desktop or NAS services into other hosts.
  den.aspects.neon-flux-theme = {
    includes = userThemes ++ [
      (whenPresent den.aspects.plasma [ den.aspects.sddm-neon-flux-theme ])
      (whenPresent den.aspects.silverbullet [ den.aspects.silverbullet-neon-flux-theme ])
    ];
  };
}
