{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../secrets/secrets.nix

    ../modules/nixos/base
    ../modules/nixos/docker
    inputs.disko.nixosModules.default
    ../disks/dock09.nix
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

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # ========================================
  # MODULE CONFIGURATION
  # ========================================
  modules.secrets = {
    preservation.enable = false;
    docker.enable = true;
    runners.enable = false;
  };

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
  networking.hostName = "dock09";
}
