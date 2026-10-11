{
  lib,
  hostName,
  path,
}:
let
  peers = {
    nas = {
      id = "TSOHEYD-X4HEYGA-SGMJAGB-Y4T3L4W-4TJXHNP-OARJCXS-FTSBWTI-Q6466QY";
      addresses = [
        "tcp://192.168.178.3:22000"
        "dynamic"
      ];
    };
    desktop.id = "HN7X6YN-DSZSUEL-SVBQDSB-4CALLWG-EC7BQNF-PG73BDF-THNF3SD-52VXBAM";
    laptop.id = "DWZKT5B-G6NYJ4K-TQI25MO-NBY6WRE-EZIKJX5-5TKZLN2-TE2WGBD-QTT2YAN";
  };
  devices = lib.filterAttrs (name: _: name != hostName) peers;
in
{
  inherit devices;
  folders.org-notes = {
    id = "org-notes";
    label = "Org notes";
    inherit path;
    type = "sendreceive";
    devices = builtins.attrNames devices;
    fsWatcherEnabled = true;
    rescanIntervalS = 300;
    maxConflicts = -1;
    ignorePatterns = [
      "!*sync-conflict-*"
      "\\#*\\#"
      ".\\#*"
      "*~"
      "*.{db,sqlite,sqlite3}-{wal,shm}"
      "org-roam.db"
    ];
  };
}
