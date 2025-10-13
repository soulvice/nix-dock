{ config, lib, pkgs, ... }: with lib; let
  cfg = config.modules.docker.swarm-manager;
in {
  # Options ===================
  options.modules.docker.swarm-manager = {
    enable = mkEnableOption "Enable Docker Swarm Token API Service" // { default = false; };
    port = mkOption {
      type = types.port;
      default = 3001;
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

    # SystemD service for the swarm token API
    systemd.services.docker-swarm-token-api = {
      description = "Docker Swarm Token API Service";
      after = [ "docker.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.docker pkgs.netcat-gnu pkgs.coreutils pkgs.gnused pkgs.gnugrep ];
      
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        User = "docker-swarm-api";
        Group = "docker";
        # Logging configuration for journald
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "docker-swarm-token-api";
      };

      script = ''
        # Function to log messages
        log() {
          echo "$(date '+%Y-%m-%d %H:%M:%S') [$$] $1" >&2
        }

        # Function to get swarm token
        get_swarm_token() {
          local token_type="$1"
          log "Requesting $token_type token"
          
          # Check if Docker swarm is active
          if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
            log "ERROR: Docker swarm is not active on this node"
            echo "HTTP/1.1 503 Service Unavailable"
            echo "Content-Type: application/json"
            echo "Content-Length: 60"
            echo ""
            echo '{"error":"Docker swarm is not active on this node"}'
            return
          fi

          # Check if this node is a manager
          if ! docker info 2>/dev/null | grep -q "Is Manager: true"; then
            log "ERROR: This node is not a swarm manager"
            echo "HTTP/1.1 403 Forbidden" 
            echo "Content-Type: application/json"
            echo "Content-Length: 50"
            echo ""
            echo '{"error":"This node is not a swarm manager"}'
            return
          fi

          # Get the token
          local token
          token=$(docker swarm join-token -q "$token_type" 2>/dev/null)
          
          if [ -z "$token" ]; then
            log "ERROR: Failed to retrieve $token_type token"
            echo "HTTP/1.1 500 Internal Server Error"
            echo "Content-Type: application/json"
            echo "Content-Length: 45"
            echo ""
            echo '{"error":"Failed to retrieve swarm token"}'
            return
          fi

          log "Successfully retrieved $token_type token"
          local response="{\"token\":\"$token\",\"type\":\"$token_type\"}"
          local content_length=$(echo -n "$response" | wc -c)
          
          echo "HTTP/1.1 200 OK"
          echo "Content-Type: application/json"
          echo "Content-Length: $content_length"
          echo ""
          echo "$response"
        }

        # Function to handle HTTP requests
        handle_request() {
          local request_line
          read -r request_line
          
          local method path
          method=$(echo "$request_line" | cut -d' ' -f1)
          path=$(echo "$request_line" | cut -d' ' -f2)
          
          log "Received $method request for $path"

          # Skip remaining headers
          while IFS= read -r line && [ "$line" != $'\r' ]; do
            continue
          done

          case "$path" in
            /swarm/worker)
              get_swarm_token "worker"
              ;;
            /swarm/manager)
              get_swarm_token "manager"
              ;;
            /health)
              log "Health check requested"
              echo "HTTP/1.1 200 OK"
              echo "Content-Type: application/json"
              echo "Content-Length: 19"
              echo ""
              echo '{"status":"healthy"}'
              ;;
            *)
              log "Unknown endpoint requested: $path"
              echo "HTTP/1.1 404 Not Found"
              echo "Content-Type: application/json"
              echo "Content-Length: 34"
              echo ""
              echo '{"error":"Endpoint not found"}'
              ;;
          esac
        }

        # Main service loop
        log "Starting Docker Swarm Token API on ${cfg.interface}:${toString cfg.port}"
        
        # Wait for Docker to be ready
        for i in {1..30}; do
          if docker info >/dev/null 2>&1; then
            break
          fi
          log "Waiting for Docker daemon to be ready..."
          sleep 2
        done

        # Check if Docker is accessible
        if ! docker info >/dev/null 2>&1; then
          log "FATAL: Docker daemon is not accessible"
          exit 1
        fi

        log "Docker daemon is ready, starting HTTP server"

        # Start the HTTP server
        while true; do
          log "Listening for connections..."
          if ! nc -l ${cfg.interface} ${toString cfg.port} -c "handle_request" 2>/dev/null; then
            log "WARNING: netcat exited, restarting in 1 second..."
            sleep 1
          fi
        done
      '';
    };

    # Create user for the service
    users.users.docker-swarm-api = {
      description = "Docker Swarm Token API Service User";
      isSystemUser = true;
      group = "docker";
      home = "/var/empty";
      shell = pkgs.bash;
    };

    # Ensure the user is in docker group
    users.groups.docker.members = [ "docker-swarm-api" ];
  };
}