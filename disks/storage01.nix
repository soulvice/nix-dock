let 
  root = {
    size = "100%";
    content = {
      type = "btrfs";
      extraArgs = [ "-f" ];
      subvolumes = {
        "@root" = {
          mountpoint = "/";
          #mountOptions = [
          #  "compress-force=zstd:1"
          #  "noatime"
          #];
        };
        "@nix" = {
          mountpoint = "/nix";
          mountOptions = [
            "compress-force=zstd:1" # Save space and reduce I/O on SSD
            "noatime"
          ];
        };
        "@home" = {
          mountpoint = "/home";
          mountOptions = [
            "compress-force=zstd:1" # Save space and reduce I/O on SSD
          ];
        };
      };
    };
  };

in {
  disko.devices = {
    disk = {
      storage01 = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "mbrTable";
          partitions = {
            inherit root;

            # -- Boot Device --
            #boot = {
            #  size = "256M";
            #  type = "EF02"; # for grub MBR
            #  attributes = [ 0 ]; # partition attribute
            #};
          };
        };
      };
    };
  };
}