{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.modules.docker;
in
{
  options.modules.docker = {
    enable = mkEnableOption "Docker configuration";

    enableGPU = mkEnableOption "Enable Nvidia GPU packages for the system";

    swarm = {
      create = mkEnableOption "Creates the docker swarm if it doesn't exist";

      join = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Token to join an existing swarm";
      };

      mode = mkOption {
        type = types.enum [ "manager" "worker" ];
        default = "worker";
        description = "Join the swarm as a manager or worker";
      };

      managerIP = mkOption {
        type = types.str;
        default = "";
        description = "IP address of the swarm manager to join";
      };

      advertiseInterface = mkOption {
        type = types.str;
        default = "ens18";
        description = "Network interface to advertise for swarm communication";
      };
    };

    storageDriver = mkOption {
      type = types.str;
      default = "btrfs";
      description = "Docker storage driver";
    };

    monitoring = {
      enable = mkEnableOption "Enable Prometheus and Promtail monitoring";

      lokiUrl = mkOption {
        type = types.str;
        default = "https://loki.svc.w0lf.io/loki/api/v1/push";
        description = "Loki endpoint URL for Promtail";
      };

      nodeExporterPort = mkOption {
        type = types.port;
        default = 9100;
        description = "Port for Prometheus Node Exporter";
      };
    };

    nfsShares = mkOption {
      type = types.listOf (types.submodule {
        options = {
          mountPoint = mkOption {
            type = types.str;
            description = "Local mount point";
          };
          device = mkOption {
            type = types.str;
            description = "NFS device path (server:/path)";
          };
        };
      });
      default = [];
      description = "NFS shares to mount for Docker";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base Docker configuration
    {
      # Docker service
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        storageDriver = cfg.storageDriver;
        liveRestore = false;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
        daemon.settings = {
          log-driver = "json-file";
          log-opts = {
            max-size = "10m";
            max-file = "3";
          };
          data-root = "/var/lib/docker";
          metrics-addr = "0.0.0.0:9323";
          experimental = true;
        };
      };

      # Firewall configuration for Docker Swarm
      networking.firewall = {
        trustedInterfaces = [ "docker0" "docker_gwbridge" ];
        allowedTCPPorts = [
          2377  # Docker Swarm management
          7946  # Container network discovery
          9323  # Docker metrics
        ];
        allowedUDPPorts = [
          4789  # Overlay network traffic
          7946  # Container network discovery
        ];
      };

      # Essential packages
      environment.systemPackages = with pkgs; [
        docker-compose
      ];
    }

    # GPU support
    (mkIf cfg.enableGPU {
      hardware.nvidia-container-toolkit.enable = true;
      hardware.graphics.enable = true;

      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
      };
    })

    # Docker Swarm configuration
    (mkIf (cfg.swarm.create || cfg.swarm.join != null) {
      systemd.services.docker-swarm-setup = {
        description = "Docker Swarm Setup";
        after = [ "docker.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iproute2 pkgs.docker pkgs.gnugrep pkgs.iputils ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "10s";
        };
        script = ''
          # Wait for network to be fully ready
          for i in {1..30}; do
            if ip addr show ${cfg.swarm.advertiseInterface} | grep -q "inet "; then
              break
            fi
            echo "Waiting for network interface ${cfg.swarm.advertiseInterface}..."
            sleep 2
          done

          # Wait for Docker to be fully ready
          for i in {1..30}; do
            if docker info >/dev/null 2>&1; then
              break
            fi
            echo "Waiting for Docker daemon..."
            sleep 2
          done

          # Check if already in a swarm
          if docker info 2>/dev/null | grep -q "Swarm: active"; then
            echo "Already part of a swarm"
            exit 0
          fi

          ${if cfg.swarm.create then ''
            # Initialize swarm
            echo "Initializing Docker Swarm..."
            SWARM_IP=$(ip -4 addr show ${cfg.swarm.advertiseInterface} | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n1)
            docker swarm init --advertise-addr $SWARM_IP 2>&1 || {
              echo "Swarm init failed or already initialized"
            }
          '' else if cfg.swarm.join != null then ''
            # Join existing swarm
            echo "Joining Docker Swarm as ${cfg.swarm.mode}..."
            SWARM_IP=$(ip -4 addr show ${cfg.swarm.advertiseInterface} | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n1)
            echo "Local IP: $SWARM_IP"
            echo "Manager IP: ${cfg.swarm.managerIP}"

            if [ -z "$SWARM_IP" ]; then
              echo "ERROR: Could not determine IP address for ${cfg.swarm.advertiseInterface}"
              exit 1
            fi

            # Test connectivity to manager
            if ! ping -c 1 -W 2 ${cfg.swarm.managerIP} >/dev/null 2>&1; then
              echo "WARNING: Cannot ping manager at ${cfg.swarm.managerIP}"
            fi

            docker swarm join \
              --token ${cfg.swarm.join} \
              --advertise-addr $SWARM_IP \
              ${cfg.swarm.managerIP}:2377 2>&1 || {
              echo "Swarm join failed or already in swarm"
            }
          '' else ""}

          echo "Swarm Status:"
          docker info | grep -A 5 "Swarm:"
        '';
      };
    })

    # Monitoring configuration
    (mkIf cfg.monitoring.enable {
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
        port = cfg.monitoring.nodeExporterPort;
        openFirewall = true;
      };

      networking.firewall.allowedTCPPorts = [ cfg.monitoring.nodeExporterPort ];

      # Promtail
      services.promtail = {
        enable = true;
        configuration = {
          server = {
            http_listen_port = 9080;
            grpc_listen_port = 0;
          };

          positions = {
            filename = "/var/log/promtail/positions.yaml";
          };

          clients = [
            {
              url = cfg.monitoring.lokiUrl;
            }
          ];

          scrape_configs = [
            # System journal logs
            {
              job_name = "systemd-journal";
              journal = {
                max_age = "12h";
                labels = {
                  job = "systemd-journal";
                  host = config.networking.hostName;
                };
              };
              relabel_configs = [
                {
                  source_labels = [ "__journal__systemd_unit" ];
                  target_label = "unit";
                }
                {
                  source_labels = [ "__journal__hostname" ];
                  target_label = "hostname";
                }
                {
                  source_labels = [ "__journal_priority_keyword" ];
                  target_label = "level";
                }
                {
                  source_labels = [ "__journal__comm" ];
                  target_label = "command";
                }
              ];
            }
            # Docker containers with service discovery
            {
              job_name = "docker";
              docker_sd_configs = [
                {
                  host = "unix:///var/run/docker.sock";
                  refresh_interval = "5s";
                }
              ];
              relabel_configs = [
                {
                  source_labels = [ "__meta_docker_container_name" ];
                  regex = "/(.*)";
                  target_label = "container";
                }
                {
                  source_labels = [ "__meta_docker_container_image" ];
                  target_label = "image";
                }
                {
                  source_labels = [ "__meta_docker_container_id" ];
                  target_label = "container_id";
                }
                {
                  source_labels = [ "__meta_docker_container_log_stream" ];
                  target_label = "stream";
                }
                {
                  source_labels = [ "__meta_docker_swarm_service_name" ];
                  target_label = "service";
                }
                {
                  source_labels = [ "__meta_docker_stack_namespace" ];
                  target_label = "stack";
                }
                {
                  source_labels = [ "__meta_docker_swarm_node_hostname" ];
                  target_label = "node";
                }
              ];
            }
          ];
        };
      };

      # Allow promtail to read Docker container logs
      systemd.services.promtail.serviceConfig = {
        ReadOnlyPaths = [ "/var/lib/docker/containers" "/var/run/docker.sock" ];
        SupplementaryGroups = [ "docker" ];
      };

      users.users.promtail = {
        isSystemUser = true;
        group = "promtail";
        extraGroups = [ "systemd-journal" "docker" ];
      };
      users.groups.promtail = {};

      systemd.tmpfiles.rules = [
        "d /var/log/promtail 0755 promtail promtail -"
      ];
    })

    # NFS shares
    (mkIf (cfg.nfsShares != []) {
      services.rpcbind.enable = true;

      fileSystems = listToAttrs (map (share: {
        name = share.mountPoint;
        value = {
          device = share.device;
          fsType = "nfs";
          options = [
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
        };
      }) cfg.nfsShares);

      systemd.tmpfiles.rules = map (share: "d ${share.mountPoint} 0755 whale docker -") cfg.nfsShares;
    })
  ]);
}
