{ config, lib, pkgs, system-hosts, hostname, ... }: with lib; let
  cfg = config.modules.docker.swarm-manager;

  # Generate list of other manager nodes from system-hosts
  otherManagers = builtins.filter
    (host: host.mode == "manager" && host.hostname != hostname)
    system-hosts;

  # Format as "addr:port" strings
  managerAddresses = map
    (host: "${host.addr}:${toString cfg.port}")
    otherManagers;

  # Join with commas for environment variable
  swarmManagersEnv = builtins.concatStringsSep "," managerAddresses;

in {
  # Options ===================
  options.modules.docker.swarm-manager = {
    enable = mkEnableOption "Enable Docker Swarm Token API Service" // { default = false; };
    port = mkOption {
      type = types.port;
      default = 3535;
      description = "Port for the swarm token API service";
    };
    interface = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Interface to bind the API service to";
    };
    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug logging for manager discovery";
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

      preStart = optionalString cfg.debug ''
        echo "=== Docker Swarm Manager Configuration ==="
        echo "Current hostname: ${hostname}"
        echo "Discovered managers: ${swarmManagersEnv}"
        echo "Manager count: ${toString (length otherManagers)}"
        echo "All system hosts:"
        ${concatMapStringsSep "\n" (host:
          "echo '  ${host.hostname} (${host.addr}) - ${host.mode}'"
        ) system-hosts}
        echo "==========================================="
      '';

      environment = {
        SWARM_TOKEN_HOST = cfg.interface;
        SWARM_TOKEN_PORT = toString cfg.port;
        SWARM_MANAGERS = swarmManagersEnv;
      };
    };
  };
}