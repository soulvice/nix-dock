{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NFS Server Settings
  services.nfs.server = {
    enable = true;
    exports = ''
      /data/store01/frigate *(rw,insecure,sync,no_subtree_check,no_root_squash)
      /data/store01/photos *(rw,insecure,sync,no_subtree_check,no_root_squash)
      /data/store01/backups *(rw,insecure,sync,no_subtree_check,no_root_squash)
      /data/store01/docker *(rw,insecure,sync,no_subtree_check,no_root_squash)
    '';
  };

  # NFS Server firewall ports
  networking.firewall.allowedTCPPorts = [
    2049
    111
    20048
  ];
  networking.firewall.allowedUDPPorts = [
    2049
    111
    20048
  ];
  networking.firewall.checkReversePath = "loose";

  # NFS performance kernel parameters
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  # SMART monitoring for disk health
  services.smartd = {
    enable = true;
    notifications.wall.enable = true;
  };

  # Additional NFS collector for Prometheus
  services.prometheus.exporters.node.enabledCollectors = [
    "nfs"
    "nfsd"
    "mountstats"
  ];

  # System packages for storage management
  environment.systemPackages = with pkgs; [
    xfsprogs
    nfs-utils
    smartmontools
    lsof
    ncdu
    iotop
  ];

  # Automatic XFS scrubbing (filesystem checking)
  systemd.services.xfs-scrub-data = {
    description = "XFS scrub for /storage/data";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.xfsprogs}/bin/xfs_scrub -v /data/store01";
    };
  };

  systemd.timers.xfs-scrub-data = {
    description = "Weekly XFS scrub timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
