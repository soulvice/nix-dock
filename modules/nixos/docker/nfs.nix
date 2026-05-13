{
  config,
  pkgs,
  lib,
  ...
}:
let
  storageHost = "10.0.1.10";
  baseFolder = "${storageHost}:/data/store01/docker";
  commonNFSOpts = [
    "nfsvers=4.2"
    "rw"
    "hard"
    "intr"
    "timeo=14"
    "rsize=32768"
    "wsize=32768"
    "_netdev"
    "nofail"
    "x-systemd.automount"
    "noauto"
  ];
in
{

  config = lib.mkMerge [
    {
      # NFS Client for shared storage
      services.rpcbind.enable = true;

      environment.systemPackages = with pkgs; [
        nfs-utils
      ];
    }
    (lib.mkIf
      (
        (config.networking.hostName == "dock01")
        || (config.networking.hostName == "dock02")
        || (config.networking.hostName == "dock03")
        || (config.networking.hostName == "dock04")
        || (config.networking.hostName == "dock05")
        || (config.networking.hostName == "dock06")
        || (config.networking.hostName == "dock07")
        || (config.networking.hostName == "dock08")
      )
      {
        # Ensure directories exist
        systemd.tmpfiles.rules = [
          "d /docker 0755 root root -"
          "d /docker/services.d 0755 whale docker -"
          "d /docker/logs.d 0755 whale docker -"
          "d /docker/shared.d 0755 whale docker -"
          "d /docker/backups.d 0755 whale docker -"
          "d /docker/local.d 0755 whale docker -"
        ];

        fileSystems."/docker/services.d" = {
          device = "${baseFolder}/services.d";
          fsType = "nfs";
          options = commonNFSOpts;
        };

        fileSystems."/docker/logs.d" = {
          device = "${baseFolder}/logs.d";
          fsType = "nfs";
          options = commonNFSOpts;
        };

        fileSystems."/docker/shared.d" = {
          device = "${baseFolder}/shared.d";
          fsType = "nfs";
          options = commonNFSOpts;
        };

        fileSystems."/docker/backups.d" = {
          device = "${baseFolder}/backups.d";
          fsType = "nfs";
          options = commonNFSOpts;
        };
      }
    )
  ];
}
