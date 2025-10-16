{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

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
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ee984dbe-e3c2-4acd-9516-d845ef70f003";
    fsType = "btrfs";
    options = [ "subvol=@root" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/ee984dbe-e3c2-4acd-9516-d845ef70f003";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/ee984dbe-e3c2-4acd-9516-d845ef70f003";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };

  fileSystems."/var/lib/docker" = {
    device = "/dev/disk/by-uuid/ee984dbe-e3c2-4acd-9516-d845ef70f003";
    fsType = "btrfs";
    options = [ "subvol=@docker" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1de10ed8-183f-4b31-916e-bb0e4cc85253";
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
      port = 9101;
    };
  };
  modules.docker = {
    metrics-port = 9323;
    mode = "manager";
    manager-addrs = [ "10.0.1.30" ]; # Empty list means create swarm (first manager)
    swarm-manager = {
      enable = true;
      port = 3535;
      interface = "0.0.0.0";
    };
  };

  # Hostname (unique per host)
  networking.hostName = "dock07";
}
