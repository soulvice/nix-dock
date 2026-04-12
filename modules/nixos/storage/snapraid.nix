{ config, pkgs, lib, ... }: let

  #disks = [
  #  { path = "/dev/disk/by-id/ata-ST10000NE0008-2JM101_ZHZ2R1RT"; name = "parity1"; type = "parity"; }
  #  { path = "/dev/disk/by-id/ata-WDC_WD101EFAX-68LDBN0_VCG8UPSP"; name = "parity2"; type = "parity"; }
  #  { path = "/mnt/disk1"; name = "disk1"; type = "data"; }
  #  { path = "/mnt/disk2"; name = "disk3"; type = "data"; }
  #  { path = "/mnt/disk3"; name = "disk3"; type = "data"; }
  #  { path = "/mnt/disk4"; name = "disk4"; type = "data"; }
  #  { path = "/mnt/disk5"; name = "disk5"; type = "data"; }
  #  { path = "/mnt/disk6"; name = "disk6"; type = "data"; }
  #  { path = "/mnt/disk7"; name = "disk7"; type = "data"; }
  #  { path = "/mnt/disk8"; name = "disk8"; type = "data"; }
  #  { path = "/mnt/disk9"; name = "disk9"; type = "data"; }
  #  { path = "/mnt/disk10"; name = "disk10"; type = "data"; }
  #];
#
  #snapraidDataDisks = builtins.listToAttrs (lib.lists.imap0 (i: d: {
  #    name = "${d.name}";
  #    value = "/mnt/${d.name}";
  #  })
  #  dataDisks);
  #parityDisks = builtins.filter (d: d.type == "parity") disks;
  #dataDisks = builtins.filter (d: d.type == "data") disks;
#
  #contentFiles =
  #  builtins.map (d: "/mnt/${d.name}/snapraid.content") dataDisks;
  #parityFiles = builtins.map (p: "/mnt/${p.name}/snapraid.parity") parityDisks;

in {
  config = lib.mkIf (config.networking.hostName == "storage02") {
    services.snapraid = {
      enable = true;

      parityFiles = [
        "/dev/disk/by-id/ata-ST10000NE0008-2JM101_ZHZ2R1RT.snapraid.parity"
        "/dev/disk/by-id/ata-WDC_WD101EFAX-68LDBN0_VCG8UPSP.snapraid.parity"
      ];

      contentFiles = [
        "/mnt/disk1/.snapraid.content"
        "/mnt/disk2/.snapraid.content"
        "/mnt/disk3/.snapraid.content"
        "/mnt/disk4/.snapraid.content"
        "/mnt/disk5/.snapraid.content"
        "/mnt/disk6/.snapraid.content"
        "/mnt/disk7/.snapraid.content"
        "/mnt/disk8/.snapraid.content"
        "/mnt/disk9/.snapraid.content"
        "/mnt/disk10/.snapraid.content"
      ];

      dataDisks = {
        d1 =  "/mnt/disk1";
        d2 =  "/mnt/disk2";
        d3 =  "/mnt/disk3";
        d4 =  "/mnt/disk4";
        d5 =  "/mnt/disk5";
        d6 =  "/mnt/disk6";
        d7 =  "/mnt/disk7";
        d8 =  "/mnt/disk8";
        d9 =  "/mnt/disk9";
        d10 = "/mnt/disk10";
      };

      exclude = [
        "*.unrecoverable"
        "/tmp/"
        "/lost+found/"
        ".Trash-*/"
        "*.!sync"
        ".DS_Store"
      ];

      sync.interval = "03:00";

      scrub = {
        plan = 12;
        interval = "Sun 04:00";
        olderThan = 10;
      };

      extraConfig = ''
        block_size 256
        autosave 500
      '';
    };
  };
}