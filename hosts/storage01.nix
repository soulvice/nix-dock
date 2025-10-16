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
    ../modules/nixos/storage
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
    device = "/dev/disk/by-uuid/6afb697a-6bac-4f7e-996d-de05c41c6871";
    fsType = "btrfs";
    options = [ "subvol=@root" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/6afb697a-6bac-4f7e-996d-de05c41c6871";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/6afb697a-6bac-4f7e-996d-de05c41c6871";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };

  # Override the default storage filesystem configuration
  fileSystems."/data/store01" = {
    device = "/dev/disk/by-uuid/56ba976a-ea5d-4460-89a1-784572611137";
    fsType = "xfs";
    options = [
      "noatime"
      "nodiratime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
    ];
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
  secrets.storage = true;

  modules.metrics = {
    prometheus = {
      enable = true;
      port = 9100;
    };

    promtail = {
      enable = true;
      url = "https://loki.svc.w0lf.io/loki/api/v1/push";
    };
  };

  # Hostname (unique per host)
  networking.hostName = "storage01";

  # Network Configuration
  networking.useDHCP = false;
  networking.interfaces.ens18 = {
    useDHCP = true;
  };

  # Firewall configuration for NFS
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
      2049 # NFS
      111 # RPC
    ];
  };
}
