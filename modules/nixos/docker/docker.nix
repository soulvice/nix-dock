{ config, lib, pkgs, ... }: with lib; let
  cfg = config.modules.docker;
  # Determine the token server port - use swarm-manager config if enabled, otherwise docker config
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
        ] ++ (if config.modules.docker.swarm-manager.enable then [ config.modules.docker.swarm-manager.port ] else []);
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
          (import ./swarm/join-worker.nix { inherit config; })
        else if (cfg.manager-addrs == []) then
          (import ./swarm/create.nix{ inherit config; })
        else
          (import ./swarm/join-manager.nix { inherit config; });

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
