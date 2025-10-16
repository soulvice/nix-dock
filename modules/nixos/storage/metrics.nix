{ config, lib, ... }:
let

  cfg = config.modules.metrics.prometheus;

in
{

  config = lib.mkIf (cfg.enable) {
    services.prometheus.exporters.node.enabledCollectors = [
      "nfs"
      "nfsd"
      "mountstats"
    ];
  };
}
