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

  #fileSystems."/" = {
  #  device = "/dev/disk/by-uuid/6afb697a-6bac-4f7e-996d-de05c41c6871";
  #  fsType = "btrfs";
  #  options = [ "subvol=@root" ];
  #};
#
  #fileSystems."/home" = {
  #  device = "/dev/disk/by-uuid/6afb697a-6bac-4f7e-996d-de05c41c6871";
  #  fsType = "btrfs";
  #  options = [ "subvol=@home" ];
  #};
#
  #fileSystems."/nix" = {
  #  device = "/dev/disk/by-uuid/6afb697a-6bac-4f7e-996d-de05c41c6871";
  #  fsType = "btrfs";
  #  options = [ "subvol=@nix" ];
  #};

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
  #  device = "/dev/disk/by-uuid/6202c37c-ea1f-4c47-8f75-d376a9efc046";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk2" = {
  #  device = "/dev/disk/by-uuid/3557bb27-426c-43e4-869c-f9a85e8b2b4f";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk3" = {
  #  device = "/dev/disk/by-uuid/d53f212d-df89-4951-b625-2670e1097e35";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk4" = {
  #  device = "/dev/disk/by-uuid/90549b5d-e3a8-4293-a35f-d363892cb668";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk5" = {
  #  device = "/dev/disk/by-uuid/a95b2885-608d-4675-8721-3ec0e50f6bcd";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk6" = {
  #  device = "/dev/disk/by-uuid/e25969e5-b095-4fba-978d-94f8b735f7f3";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk7" = {
  #  device = "/dev/disk/by-uuid/71c7c5af-ac6d-40bf-93d7-3a81bd9a4d68";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk8" = {
  #  device = "/dev/disk/by-uuid/e126a0c0-15e4-4912-85d6-2de027408af6";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk9" = {
  #  device = "/dev/disk/by-uuid/ee9a633e-101a-4c43-898e-67a90fca0131";
  #  fsType = "xfs";
  #  options = [ "rw" "noatime" "nouuid" "attr2" "inode64" "logbufs=8" "logbsize=32k" "noquota" ];
  #};
#
  #fileSystems."/mnt/disk10" = {
  #  device = "/dev/disk/by-uuid/a90f1f15-819b-4f18-8ef1-abbdbe1b70f0";
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
