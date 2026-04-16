{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NFS Server Settings
  config = lib.mkMerge [
    # -- Storage01 --
    (lib.mkIf (config.networking.hostName == "storage01") {
      services.nfs.server = {
        enable = true;
        mountdPort = 20048;
        exports = ''
          /data/store01/frigate *(rw,insecure,sync,no_subtree_check,no_root_squash)
          /data/store01/photos *(rw,insecure,sync,no_subtree_check,no_root_squash)
          /data/store01/backups *(rw,insecure,sync,no_subtree_check,no_root_squash)
          /data/store01/docker *(rw,insecure,sync,no_subtree_check,no_root_squash)
        '';
      };

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
    })

    # -- Storage02 --
    (lib.mkIf (config.networking.hostName == "storage02") {
      services.nfs.server = {
        enable = true;
        mountdPort = 20048;
        exports = ''
          /data-pool/Media *(rw,insecure,sync,no_subtree_check,no_root_squash,softreval,timeo=150,retrans=3,fsid=1)
          /data-pool/drop *(rw,insecure,sync,no_subtree_check,no_root_squash,softreval,timeo=150,retrans=3,fsid=2)
          /data-pool/shared *(rw,insecure,sync,no_subtree_check,no_root_squash,softreval,timeo=150,retrans=3,fsid=3)
          /data-pool/backup *(rw,insecure,sync,no_subtree_check,no_root_squash,softreval,timeo=150,retrans=3,fsid=4)
        '';
      };
    })


    # -- Generic NFS Config --
    {
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

      # System packages for storage management
      environment.systemPackages = with pkgs; [
        xfsprogs
        nfs-utils
        smartmontools
        lsof
        ncdu
        iotop
      ];
    }
  ];
}
