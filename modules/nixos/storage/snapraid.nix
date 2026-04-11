{ config, pkgs, lib, ... }: let

in {
  config = lib.mkIf (config.networking.hostName == "storage02") {
    services.snapraid = {
      enable = true;

      parityFiles = [
        "/dev/disk/by-id/ata-ST10000NE0008-2JM101_ZHZ2R1RT.parity"
        "/dev/disk/by-id/ata-WDC_WD101EFAX-68LDBN0_VCG8UPSP.parity-2"
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