{ config, lib, pkgs, ... }: with lib; let
  cfg = config.modules.docker;
  # Determine the token server port - use swarm-manager config if enabled, otherwise docker config
  tokenServerPort =
    if config.modules.docker.swarm-manager.enable
    then toString config.modules.docker.swarm-manager.port
    else toString cfg.swarm-manager.port;
in{
  # Options ===================
  options.modules.docker = {
    enableGPU = mkEnableOption "Enable Docker GPU" // { default = false; };
    mode = mkOption {
      type = types.enum [ "worker" "manager" ];
      default = "worker";
      description = "Docker swarm host mode";
    };
    # Swarm tokens will be retrieved from manager addresses dynamically
    manager-addrs = mkOption {
      type = types.listOf types.string;
      default = [];
      description = "List of Manager Node IP addresses";
    };
    # Logic:
    # - if mode == "manager" && manager-addrs == [] create swarm
    # - if mode == "manager" && manager-addrs != [] join as manager
    # - if mode == "worker" join as worker

    metrics-port = mkOption {
      type = types.port;
      default = 9323;
      description = "Metrics port for docker daemon";
    };

    swarm-manager = {
      enable = mkEnableOption "Enable Swarm token distribution server" // { default = false; };
      port = mkOption {
        type = types.port;
        default = 3505;
        description = "Port for swarm token distribution server";
      };
      interface = mkOption {
        type = types.string;
        default = "0.0.0.0";
        description = "Interface to bind token server to";
      };
    };
  };


  config = mkMerge [
    {
      # Docker service
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        storageDriver = "btrfs";
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
          metrics-addr = "0.0.0.0:${toString cfg.metrics-port}";
          experimental = true;
        };
      };

      # Firewall configuration for Docker Swarm
      networking.firewall = {
        trustedInterfaces = [ "docker0" "docker_gwbridge" ];
        allowedTCPPorts = [
          2377  # Docker Swarm management
          7946  # Container network discovery
          cfg.metrics-port  # Docker metrics
        ] ++ (if cfg.swarm-manager.enable then [ cfg.swarm-manager.port ] else []);
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
      # Enable CDI for Docker
      virtualisation.docker.daemon.settings.features.cdi = true;

      # NVIDIA Docker Support
      hardware.nvidia-container-toolkit.enable = true;
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      # Additional NVIDIA packages
      environment.systemPackages = with pkgs; [
        nvidia-docker
        pciutils
        nvidia-container-toolkit
        libnvidia-container
      ];

      # NVIDIA GPU Exporter (uses nvidia-smi)
      services.prometheus.exporters.nvidia-gpu = {
        enable = true;
        port = cfg.metrics-port;
        openFirewall = true;
      };
    })

    # SWARM SYSTEMD ===========================
    # =========================================
    {
      systemd.services.docker-swarm-setup = let
        managerAddrs = builtins.concatStringsSep " " cfg.manager-addrs;
        joiner = if (cfg.mode == "worker") then
          ''# Join as worker
          echo "Joining Docker Swarm as worker..."
          SWARM_IP=$(ip -4 addr show ens18 | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n1)
          echo "Local IP: $SWARM_IP"

          if [ -z "$SWARM_IP" ]; then
            echo "ERROR: Could not determine IP address for ens18"
            exit 1
          fi

          # Try each manager address until one works
          MANAGER_ADDRS=(${managerAddrs})
          WORKER_TOKEN=""
          WORKING_MANAGER=""

          for MANAGER_IP in "''${MANAGER_ADDRS[@]}"; do
            echo "Trying manager: $MANAGER_IP"

            # Test connectivity to manager via health endpoint
            echo "Checking health endpoint at $MANAGER_IP..."
            if ! curl -s --connect-timeout 5 --max-time 10 "http://$MANAGER_IP:${tokenServerPort}/health" >/dev/null 2>&1; then
              echo "WARNING: Health check failed for manager at $MANAGER_IP:${tokenServerPort}"
              continue
            fi

            # Retrieve worker token from manager API
            echo "Retrieving worker token from manager API at $MANAGER_IP..."
            API_RESPONSE=$(curl -s --connect-timeout 10 --max-time 30 "http://$MANAGER_IP:${tokenServerPort}/swarm/worker" 2>/dev/null || {
              echo "ERROR: Failed to retrieve worker token from manager API at $MANAGER_IP:${tokenServerPort}"
              continue
            })

            WORKER_TOKEN=$(echo "$API_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

            if [ -n "$WORKER_TOKEN" ]; then
              WORKING_MANAGER="$MANAGER_IP"
              echo "Retrieved worker token successfully from $MANAGER_IP"
              break
            else
              echo "ERROR: Retrieved empty worker token from $MANAGER_IP. API Response: $API_RESPONSE"
            fi
          done

          if [ -z "$WORKER_TOKEN" ] || [ -z "$WORKING_MANAGER" ]; then
            echo "ERROR: Failed to retrieve worker token from any manager"
            exit 1
          fi

          docker swarm join --token "$WORKER_TOKEN" --advertise-addr $SWARM_IP "$WORKING_MANAGER:2377" 2>&1 || {
            echo "Swarm join failed or already in swarm"
          }

          echo "Swarm Status:"
          docker info | grep -A 5 "Swarm:"''
        else if (cfg.manager-addrs == []) then
          ''# Create swarm as first manager
            echo "Creating Docker Swarm as first manager..."
            SWARM_IP=$(ip -4 addr show ens18 | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n1)
            echo "Using IP: $SWARM_IP"

            if [ -z "$SWARM_IP" ]; then
              echo "ERROR: Could not determine IP address for ens18"
              exit 1
            fi

            docker swarm init --advertise-addr $SWARM_IP 2>&1 || {
              echo "Swarm init failed or already initialized"
            }

            echo "Swarm Status:"
            docker info | grep -A 5 "Swarm:"''
        else
          ''# Join existing swarm as manager
            echo "Joining existing Docker Swarm as manager..."
            SWARM_IP=$(ip -4 addr show ens18 | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n1)
            echo "Local IP: $SWARM_IP"

            if [ -z "$SWARM_IP" ]; then
              echo "ERROR: Could not determine IP address for ens18"
              exit 1
            fi

            # Try each manager address until one works
            MANAGER_ADDRS=(${managerAddrs})
            MANAGER_TOKEN=""
            WORKING_MANAGER=""

            for MANAGER_IP in "''${MANAGER_ADDRS[@]}"; do
              echo "Trying manager: $MANAGER_IP"

              # Test connectivity to manager via health endpoint
              echo "Checking health endpoint at $MANAGER_IP..."
              if ! curl -s --connect-timeout 5 --max-time 10 "http://$MANAGER_IP:${tokenServerPort}/health" >/dev/null 2>&1; then
                echo "WARNING: Health check failed for manager at $MANAGER_IP:${tokenServerPort}"
                continue
              fi

              # Retrieve manager token from manager API
              echo "Retrieving manager token from manager API at $MANAGER_IP..."
              API_RESPONSE=$(curl -s --connect-timeout 10 --max-time 30 "http://$MANAGER_IP:${tokenServerPort}/swarm/manager" 2>/dev/null || {
                echo "ERROR: Failed to retrieve manager token from manager API at $MANAGER_IP:${tokenServerPort}"
                continue
              })

              MANAGER_TOKEN=$(echo "$API_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

              if [ -n "$MANAGER_TOKEN" ]; then
                WORKING_MANAGER="$MANAGER_IP"
                echo "Retrieved manager token successfully from $MANAGER_IP"
                break
              else
                echo "ERROR: Retrieved empty manager token from $MANAGER_IP. API Response: $API_RESPONSE"
              fi
            done

            if [ -z "$MANAGER_TOKEN" ] || [ -z "$WORKING_MANAGER" ]; then
              echo "ERROR: Failed to retrieve manager token from any manager"
              exit 1
            fi

            docker swarm join --token "$MANAGER_TOKEN" --advertise-addr $SWARM_IP "$WORKING_MANAGER:2377" 2>&1 || {
              echo "Swarm join failed or already in swarm"
            }

            echo "Swarm Status:"
            docker info | grep -A 5 "Swarm:"'';
      in{
        description = "Docker Swarm Setup";
        after = [ "docker.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iproute2 pkgs.docker pkgs.gnugrep pkgs.curl ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "10s";
        };
        script = ''
          # Wait for network to be fully ready
          for i in {1..30}; do
            if ip addr show ens18 | grep -q "inet "; then
              break
            fi
            echo "Waiting for network interface ens18..."
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

          ${joiner}
        '';
      };
    }

  ];
}
