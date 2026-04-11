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
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "450M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0177" # File mask: 777-177=600 (Owner: rw-, Group/Others: ---)
                  "dmask=0077" # Directory mask: 777-077=700 (Owner: rwx, Group/Others: ---)
                  "noexec,nosuid,nodev" # Security: Block execution, ignore setuid, and disable device nodes
                ];
              };
            };

          };
        };
      };
      storage01 = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            inherit root;

            # -- Boot Device --
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "450M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0177" # File mask: 777-177=600 (Owner: rw-, Group/Others: ---)
                  "dmask=0077" # Directory mask: 777-077=700 (Owner: rwx, Group/Others: ---)
                  "noexec,nosuid,nodev" # Security: Block execution, ignore setuid, and disable device nodes
                ];
              };
            };
          };
        };
      };
    };
  };
}