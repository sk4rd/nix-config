{ path, devices }:
{
  id = "hermes-profiles";
  label = "Hermes profiles";
  inherit path devices;
  type = "sendreceive";
  fsWatcherEnabled = true;
  rescanIntervalS = 300;
  maxConflicts = -1;
  # First match wins; negations also allow traversal of parent directories.
  ignorePatterns = [
    "!skills"
    "!*.md"
    "*"
  ];
}
