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
      storage02 = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            inherit root;

            # -- Boot Device --
            boot = {
              size = "1M";
              type = "EF02";
            };
          };
        };
      };
    };
  };
}