{ config, lib, pkgs, ... }: with lib; let
  cfg = config.modules.docker.swarm-manager;
in {
  # Options ===================
  options.modules.docker.swarm-manager = {
    enable = mkEnableOption "Enable Docker Swarm Token API Service" // { default = false; };
    port = mkOption {
      type = types.port;
      default = 3505;
      description = "Port for the swarm token API service";
    };
    interface = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Interface to bind the API service to";
    };
  };

  # Configuration ==============
  config = mkIf cfg.enable {
    # Firewall configuration
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # SystemD service for the swarm token API (Python-based)
    systemd.services.docker-swarm-token-api = {
      description = "Docker Swarm Token Distribution Server";
      after = [ "docker.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.python3 pkgs.docker ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        User = "root";  # Needs root for docker commands
        ExecStart = "${pkgs.python3}/bin/python3 ${./swarm-token-server.py}";
      };

      environment = {
        SWARM_TOKEN_HOST = cfg.interface;
        SWARM_TOKEN_PORT = toString cfg.port;
      };
    };
  };
}