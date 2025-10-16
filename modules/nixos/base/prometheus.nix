{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:
let

  cfg = config.modules.metrics.prometheus;

in
{
  options.modules.metrics.prometheus = {
    enable = lib.mkEnableOption "Enable Prometheus Metrics" // {
      default = true;
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Network port to use for metrics";
      default = 9100;
    };
  };

  config = lib.mkIf (cfg.enable) {
    # Firewall configuration for Docker Swarm + Monitoring
    networking.firewall = {
      allowedTCPPorts = [
        cfg.port # Node Exporter
      ];
    };

    # Prometheus Node Exporter
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "systemd"
        "processes"
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "netstat"
        "stat"
        "time"
        "uname"
        "vmstat"
      ];
      port = cfg.port;
      openFirewall = true;
    };
  };
}
