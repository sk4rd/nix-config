{
  den.aspects.media = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [

          yt-dlp
          mpv
          ffmpeg
        ];
      };
  };
}
