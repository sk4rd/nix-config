{ ... }:
let
  home = "/home/miko";
  videoPlayer = "mpv.desktop";
  imageViewer = "imv.desktop";
  emacs = "emacs.desktop";
  videoMimeTypes = [
    "video/mp4"
    "video/webm"
    "video/x-matroska"
    "video/x-msvideo"
    "video/quicktime"
    "video/x-ms-wmv"
    "video/mpeg"
    "video/ogg"
    "video/x-flv"
  ];
  imageMimeTypes = [
    "image/jpeg"
    "image/png"
    "image/gif"
    "image/webp"
    "image/tiff"
    "image/svg+xml"
  ];
  programmingMimeTypes = [
    "text/html"
    "text/css"
    "application/javascript"
    "application/json"
    "text/xml"
    "application/x-python"
    "application/x-shellscript"
    "text/x-csrc"
    "text/x-c++src"
    "application/x-java"
  ];
  configMimeTypes = [ "text/x-yaml" "application/x-toml" ];
  textMimeTypes = [ "text/plain" "text/markdown" "text/x-tex" ];
  emacsSpecificMimeTypes = [
    "text/x-nix"
    "text/x-shellscript"
    "text/plain" # for .conf, .org, .el files
  ];
in {
  xdg = {
    enable = true;
    cacheHome = "${home}/.local/cache";
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${home}/dsktp";
      documents = "${home}/docs";
      download = "${home}/dwnld";
      music = "${home}/music";
      pictures = "${home}/pics";
      publicShare = "${home}/dsktp";
      templates = "${home}/dsktp";
      videos = "${home}/vids";
      extraConfig = { XDG_SCREENSHOTS_DIR = "${home}/pics/screenshots"; };
    };
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = builtins.listToAttrs (map (mimeType: {
        name = mimeType;
        value = [ videoPlayer ];
      }) videoMimeTypes ++ map (mimeType: {
        name = mimeType;
        value = [ imageViewer ];
      }) imageMimeTypes ++ map (mimeType: {
        name = mimeType;
        value = [ emacs ];
      }) (textMimeTypes ++ programmingMimeTypes ++ configMimeTypes
        ++ emacsSpecificMimeTypes));
    };
  };
}
