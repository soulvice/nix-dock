<<<<<<< HEAD
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
        "@docker" = {
          mountpoint = "/var/lib/docker";
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
      dock09 = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "mbr";
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
||||||| 7419ada
=======
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
        "@docker" = {
          mountpoint = "/var/lib/docker";
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
          type = "mbr";
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
>>>>>>> 62b829da946bb9bcdba0311207d7150955d5172b
