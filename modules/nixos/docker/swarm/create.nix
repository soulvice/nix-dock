{ ... }:
''
  # Create swarm as first manager
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
  docker info | grep -A 5 "Swarm:"
''