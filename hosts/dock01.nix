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
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/72578c59-8c77-40ba-b7b0-51644521b621";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/72578c59-8c77-40ba-b7b0-51644521b621";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/72578c59-8c77-40ba-b7b0-51644521b621";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/var/lib/docker" =
    { device = "/dev/disk/by-uuid/72578c59-8c77-40ba-b7b0-51644521b621";
      fsType = "btrfs";
      options = [ "subvol=@docker" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/863b5741-6cf6-4d59-8569-6b32edb19c8a";
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
  networking.hostName = "dock01";
}
