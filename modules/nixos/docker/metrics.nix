{ config, lib, pkgs, ... }: let

  cfg = config.modules.metrics.cadvisor;

in{
  
  options.modules.metrics.cadvisor = {
    enable = lib.mkEnableOption "Enable cAdvisor for docker container metrics";
    port = lib.mkOption {
      type = lib.types.port;
      description = "Network port to use for metrics";
      default = 9101;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      cadvisor
    ];

    services.cadvisor = {
      enable = true;
      port = cfg.port;
      listenAddress = "0.0.0.0";
    };

    networking.firewall = {
      allowedTCPPorts = [
        cfg.port  # cAdvisor metrics
      ];
    };
  };
}