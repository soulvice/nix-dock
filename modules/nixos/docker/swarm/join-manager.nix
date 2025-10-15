{ config, ... }:let

  cfg = config.modules.docker;

  tokenServerPort = toString config.modules.docker.swarm-manager.port;

  managerAddrs = builtins.concatStringsSep " " cfg.manager-addrs;

in ''
  # Join existing swarm as manager
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
  docker info | grep -A 5 "Swarm:"''