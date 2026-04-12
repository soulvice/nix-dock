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
    "ata-ST4000VN008-2DR166_ZGY2HRP4"
    "ata-ST4000VN008-2DR166_ZGY2P1HF"
    "ata-ST4000VN008-2DR166_ZDH3RE3G"
    "ata-ST4000VN008-2DR166_ZGY2P3CH"
    "ata-ST4000VN008-2DR166_ZDH3QWHT"
    "ata-ST8000AS0002-1NA17Z_Z840L0LM"
    "ata-ST6000VN001-2BB186_ZCT2X26Y"
    "ata-ST6000VN001-2BB186_ZCT3122M"
    "ata-WDC_WD80EFBX-68AZZN0_VRHBVKGK"
    "ata-WDC_WD80EFBX-68AZZN0_VRHBVZZK"
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

  #fileSystems."/mnt/disk1" = {
  #  device = "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY2HRP4";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk2" = {
  #  device = "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY2P1HF";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk3" = {
  #  device = "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZDH3RE3G";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk4" = {
  #  device = "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY2P3CH";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk5" = {
  #  device = "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZDH3QWHT";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk6" = {
  #  device = "/dev/disk/by-id/ata-ST8000AS0002-1NA17Z_Z840L0LM";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk7" = {
  #  device = "/dev/disk/by-id/ata-ST6000VN001-2BB186_ZCT2X26Y";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk8" = {
  #  device = "/dev/disk/by-id/ata-ST6000VN001-2BB186_ZCT3122M";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk9" = {
  #  device = "/dev/disk/by-id/ata-WDC_WD80EFBX-68AZZN0_VRHBVKGK";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk10" = {
  #  device = "/dev/disk/by-id/ata-WDC_WD80EFBX-68AZZN0_VRHBVZZK";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/data-pool" = {
  #  device = "/mnt/disk1:/mnt/disk2:/mnt/disk3:/mnt/disk4:/mnt/disk5:/mnt/disk6:/mnt/disk7:/mnt/disk8:/mnt/disk9:/mnt/disk10";
  #  fsType = "fuse.mergerfs";
  #  options = [
  #    "defaults"
  #    "allow_other"
  #    "use_ino"              # stable inodes — required for *arr hardlinks
  #    "cache.files=off"      # avoid stale reads on multi-host setups
  #    "dropcacheonclose=true"
  #    "category.create=mfs"  # most-free-space placement
  #    "minfreespace=20G"     # don't fill drives to 100%
  #    "fsname=mergerfs"
  #  ];
  #  depends = [
  #    "/mnt/disk1" "/mnt/disk2" "/mnt/disk3" "/mnt/disk4" "/mnt/disk5"
  #    "/mnt/disk6" "/mnt/disk7" "/mnt/disk8" "/mnt/disk9" "/mnt/disk10"
  #  ];
  #};

  fileSystems = lib.listToAttrs diskMounts // {
    "/data-pool" = {
      device  = lib.concatStringsSep ":" diskPaths;
      fsType  = "fuse.mergerfs";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=off"
        "dropcacheonclose=true"
        "category.create=mfs"
        "minfreespace=20G"
        "fsname=mergerfs"
      ];
      depends = diskPaths;
    };
  };


  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # ========================================
  # HOST-SPECIFIC CONFIGURATION
  # ========================================
  # Bootloader for BIOS
  #boot.loader.grub = {
  #  enable = true;
  #  device = "/dev/sda";
  #    mirroredBoots = [];    # explicitly empty, or just omit it entirely
  #};

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
