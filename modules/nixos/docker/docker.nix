{ config, lib, ... }: with lib; let
  cfg = config.modules.docker;
in{
  # Options ===================
  options.modules.docker = {
    enableGPU = mkEnableOption "Enable Docker GPU" // { default = false; };
    mode = mkOption {
      type = types.enum [ "worker" "manager" ];
      default = "worker";
      description = "Docker swarm host mode";
    };
    # Worker SWMTKN-1-4i882kdla35vjt6lt20pm6h3vubxhprjekw9ewn5zxedsb6jsm-1lwli46y9yk6swqolij3zoiuh
    # Manager 
    swarm-token = mkOption {
      type = types.string;
      description = "Swarm Token to Use";
    };
    manager-ip = mkOption {
      type = types.string;
      description = "IP Address of Manager Node";
    };
    metrics-port = mkOption {
      type = types.port;
      default = 9323;
      description = "Metrics port for docker daemon";
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
          metrics-addr = "0.0.0.0:${cfg.metrics-port}";
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
        joiner = if (cfg.mode == "worker") then
          ''# Join as worker
          echo "Joining Docker Swarm as worker..."
          SWARM_IP=$(ip -4 addr show ens18 | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n1)
          echo "Local IP: $SWARM_IP"
          echo "Manager IP: ${cfg.manager-ip}"

          if [ -z "$SWARM_IP" ]; then
            echo "ERROR: Could not determine IP address for ens18"
            exit 1
          fi

          # Test connectivity to manager
          if ! ping -c 1 -W 2 ${cfg.manager-ip} >/dev/null 2>&1; then
            echo "WARNING: Cannot ping manager at ${cfg.manager-ip}"
          fi

          docker swarm join --token ${cfg.swarm-token} --advertise-addr $SWARM_IP ${cfg.manager-ip}:2377 2>&1 || {
            echo "Swarm join failed or already in swarm"
          }

          echo "Swarm Status:"
          docker info | grep -A 5 "Swarm:"''
        else
          ''# Initialize as manager
            echo "Initializing Docker Swarm as manager..."
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
            docker info | grep -A 5 "Swarm:'';
      in{
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