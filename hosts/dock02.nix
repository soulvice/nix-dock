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
    { device = "/dev/disk/by-uuid/ae75a95b-561b-4fcd-a657-8d7220ba5aa1";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/ae75a95b-561b-4fcd-a657-8d7220ba5aa1";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/ae75a95b-561b-4fcd-a657-8d7220ba5aa1";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/var/lib/docker" =
    { device = "/dev/disk/by-uuid/ae75a95b-561b-4fcd-a657-8d7220ba5aa1";
      fsType = "btrfs";
      options = [ "subvol=@docker" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/74299ef8-002b-47d3-b3bc-46b9a955afe4";
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
  secrets.preservation = false;
  secrets.docker = true;

  # Custom Modules
  modules.metrics = {
    prometheus = {
      enable = true;
      port = 9100;
    };
    promtail = {
      enable = true;
      url = "https://loki.svc.w0lf.io/loki/api/v1/push";
    };
    cadvisor = {
      enable = true;
      port 9101;
    };
  };

  modules.docker = {
    enableGPU = true;
    metrics-port = 9323;
    mode = "worker";
    manager-addrs = [
      "10.0.1.30"
      "10.0.1.37"
      "10.0.1.38"
    ];
  };

  # Hostname (unique per host)
  networking.hostName = "dock02";
}
