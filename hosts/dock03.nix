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
    { device = "/dev/disk/by-uuid/c44ce2ef-db44-4428-9108-3f7253d818a6";
      fsType = "btrfs";
      options = [ "subvol=@root" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/c44ce2ef-db44-4428-9108-3f7253d818a6";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/c44ce2ef-db44-4428-9108-3f7253d818a6";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/var/lib/docker" =
    { device = "/dev/disk/by-uuid/c44ce2ef-db44-4428-9108-3f7253d818a6";
      fsType = "btrfs";
      options = [ "subvol=@docker" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/49e5c127-32bb-44c9-95ed-d56b80b7069c";
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
  modules.secrets.preservation.enable = false;
  modules.secrets.docker.enable = true;

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
      port = 9101;
    };
  };

  modules.docker = {
    enableGPU = false;
    metrics-port = 9323;
    mode = "worker";
    manager-addrs = [
      "10.0.1.30"
      "10.0.1.37"
      "10.0.1.38"
    ];
  };


  # Hostname (unique per host)
  networking.hostName = "dock03";
}
