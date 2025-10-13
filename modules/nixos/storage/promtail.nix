{ config, lib, ... }: let

  cfg = config.modules.metrics.promtail;

in{
  config = lib.mkIf (cfg.enable) {
    services.promtail.configuration.scrape_configs = [
      # NFS logs
      {
        job_name = "nfs";
        static_configs = [{
          targets = [ "localhost" ];
          labels = {
            job = "nfs-server";
            host = "nixos-nfs";
            __path__ = "/var/log/nfs*";
          };
        }];
      }
    ];
  };
}