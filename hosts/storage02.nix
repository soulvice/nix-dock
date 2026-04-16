{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}: let 

  xfsDisk = id: {
    device = "/dev/disk/by-id/${id}";
    fsType = "xfs";
    options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  };

  diskIds = [
  "scsi-0QEMU_QEMU_HARDDISK_ZGY2HRP4-part1"   # disk1  4TB
  "scsi-0QEMU_QEMU_HARDDISK_ZGY2P1HF-part1"   # disk2  4TB
  "scsi-0QEMU_QEMU_HARDDISK_ZDH3RE3G-part1"   # disk3  4TB
  "scsi-0QEMU_QEMU_HARDDISK_ZGY2P3CH-part1"   # disk4  4TB
  "scsi-0QEMU_QEMU_HARDDISK_ZDH3QWHT-part1"   # disk5  4TB
  "scsi-0QEMU_QEMU_HARDDISK_Z840L0LM-part1"   # disk6  8TB
  "scsi-0QEMU_QEMU_HARDDISK_ZCT2X26Y-part1"   # disk7  6TB
  "scsi-0QEMU_QEMU_HARDDISK_ZCT3122M-part1"   # disk8  6TB
  "scsi-0QEMU_QEMU_HARDDISK_VRHBVKGK-part1"   # disk9  8TB
  "scsi-0QEMU_QEMU_HARDDISK_VRHBVZZK-part1"   # disk10 8TB
];

  diskMounts = lib.imap1 (n: id: {
    name  = "/mnt/disk${toString n}";
    value = xfsDisk id;
  }) diskIds;

  diskPaths = map (d: d.name) diskMounts;

in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../modules/nixos/base
    ../modules/nixos/storage
    ../secrets/secrets.nix
    inputs.disko.nixosModules.default
    ../disks/storage02.nix
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

  # -- MERGERFS --
  environment.systemPackages = with pkgs; [
    mergerfs
    snapraid
    smartmontools
    hdparm
    iotop
    ncdu
  ];

  fileSystems = lib.listToAttrs diskMounts // {
    "/data-pool" = {
      device  = lib.concatStringsSep ":" diskPaths;
      fsType  = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=auto-full"
        "dropcacheonclose=true"
        "category.create=mfs"
        "minfreespace=20G"
        "fsname=mergerfs"
        "nfsopenhack=all"
      ];
      depends = diskPaths;
    };
  };


  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # ========================================
  # MODULE CONFIGURATION
  # ========================================
  modules.secrets.preservation.enable = false;
  modules.secrets.storage.enable = true;

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
  networking.hostName = "storage02";

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
