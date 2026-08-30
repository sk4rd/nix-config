{
  den.aspects.media.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Media utilities
        yt-dlp
        mpv
        ffmpeg
        localsend
      ];
    };
}
