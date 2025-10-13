{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../modules/nixos/base
    ../modules/nixos/docker
    ../secrets/secrets.nix
  ];

  # ========================================
  # HARDWARE CONFIGURATION (unique to this host)
  # ========================================
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/c175d6cc-7db0-4bcb-b13b-10d32af9cd88";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/c175d6cc-7db0-4bcb-b13b-10d32af9cd88";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/c175d6cc-7db0-4bcb-b13b-10d32af9cd88";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/var/lib/docker" =
    { device = "/dev/disk/by-uuid/c175d6cc-7db0-4bcb-b13b-10d32af9cd88";
      fsType = "btrfs";
      options = [ "subvol=@docker" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/bfc36240-9915-4506-9ff0-f3846ddb1470";
      fsType = "ext4";
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # ========================================
  # HOST-SPECIFIC CONFIGURATION
  # ========================================
  # Bootloader for BIOS
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  # ========================================
  # MODULE CONFIGURATION
  # ========================================
  modules.docker = { };
  secrets.preservation = false;
  secrets.docker = true;

  # Hostname (unique per host)
  networking.hostName = "dock05";
}
