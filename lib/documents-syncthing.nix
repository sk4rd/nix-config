{ path, devices }:
{
  id = "documents";
  label = "Documents";
  inherit path devices;
  type = "sendreceive";
  fsWatcherEnabled = true;
  rescanIntervalS = 300;
  maxConflicts = -1;
  ignorePatterns = [
    "!*sync-conflict-*"
    "/notes/**/\\#*\\#"
    "/notes/**/.\\#*"
    "/notes/**/*~"
    "/notes/**/*.{db,sqlite,sqlite3}-{wal,shm}"
    "/notes/**/org-roam.db"
  ];
}
