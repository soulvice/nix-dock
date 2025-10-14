# NixOS Docker Infrastructure Flake

Multi-host NixOS flake for managing Docker Swarm infrastructure with monitoring and automated token distribution.

## Structure

```
.
├── flake.nix                    # Main flake entry point
├── modules/nixos/              # Shared NixOS modules
│   ├── base/                   # Common base configuration
│   ├── docker/                 # Docker Swarm configuration
│   │   └── docker.nix         # Main Docker module with auto-join
│   └── ...
└── hosts/                      # Per-host configurations
    ├── dock01.nix             # Primary manager node
    ├── dock02.nix             # GPU worker node
    └── ...
```

## Hosts

### Docker Swarm Architecture
- **dock01**: Primary manager node (creates swarm, runs token webserver)
- **dock02**: GPU-enabled worker node
- **Additional nodes**: Can be configured as managers or workers

### Storage Integration (Optional)
- NFS storage servers can be added for shared container volumes

## Features

### All Hosts
- ✅ Prometheus node_exporter for metrics
- ✅ Promtail for log shipping to Loki
- ✅ Tailscale for secure networking
- ✅ Automated SSH key management
- ✅ Common system packages

### Docker Swarm Features
- ✅ Docker with btrfs storage driver
- ✅ Automated swarm join with failover
- ✅ Multi-manager token distribution system
- ✅ Health-based connectivity checks (no ping dependency)
- ✅ Docker container log collection
- ✅ Automatic pruning
- ✅ Docker metrics exporter

### Manager Nodes
- ✅ Swarm initialization (primary manager)
- ✅ Token distribution webserver
- ✅ Manager join capability to existing swarms
- ✅ Health endpoint for connectivity testing

### Worker Nodes
- ✅ Multi-manager failover support
- ✅ Automatic token retrieval
- ✅ GPU support (when enabled)

## Usage

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone <repo-url> /docker/shared.d/nix-dock
   cd /docker/shared.d/nix-dock
   ```

2. **Configure hardware for each host:**
   - Generate hardware configuration on the target host:
     ```bash
     nixos-generate-config --show-hardware-config
     ```
   - Copy the output to `hosts/<hostname>/hardware-configuration.nix`
   - Customize filesystem UUIDs, network interfaces, etc.

3. **Configure Docker Swarm topology:**
   - Configure the primary manager (creates swarm)
   - Configure additional managers and workers with manager addresses
   - Update SSH authorized keys and other host-specific settings

### Building and Deploying

#### Build a specific host configuration:
```bash
nixos-rebuild build --flake .#dock01
nixos-rebuild build --flake .#dock02
nixos-rebuild build --flake .#storage01
```

#### Deploy to a host (run on the target machine):
```bash
sudo nixos-rebuild switch --flake /docker/shared.d/nix-dock#dock01
```

#### Deploy remotely (from your workstation):
```bash
nixos-rebuild switch --flake .#dock01 --target-host whale@dock01 --use-remote-sudo
```

### Development

#### Enable pre-commit hooks:
```bash
nix develop
```

This will set up automatic formatting and linting for Nix files.

#### Format all Nix files:
```bash
nix fmt
```

#### Run checks:
```bash
nix flake check
```

## Docker Swarm Configuration

### Node Types and Configuration

#### Primary Manager Node (Creates Swarm)
```nix
modules.docker = {
  mode = "manager";
  manager-addrs = []; # Empty list = create swarm
  metrics-port = 9323;
  # Optional: token webserver configuration
  swarm-manager = {
    enable = true;
    port = 3505;
    interface = "0.0.0.0";
  };
};
```

#### Additional Manager Node (Joins Existing Swarm)
```nix
modules.docker = {
  mode = "manager";
  manager-addrs = [
    "10.0.1.30"  # Primary manager IP
    "10.0.1.31"  # Other manager IPs (for failover)
  ];
  metrics-port = 9323;
};
```

#### Worker Node
```nix
modules.docker = {
  mode = "worker";
  manager-addrs = [
    "10.0.1.30"  # Manager IPs (tries in order)
    "10.0.1.31"
    "10.0.1.32"
  ];
  metrics-port = 9323;
  enableGPU = true; # Optional: for GPU workers
};
```

### Token Distribution System

The system uses a webserver on manager nodes to distribute join tokens:

- **Health endpoint**: `http://MANAGER_IP:3505/health` (connectivity check)
- **Worker tokens**: `http://MANAGER_IP:3505/swarm/worker`
- **Manager tokens**: `http://MANAGER_IP:3505/swarm/manager`

### Join Process Flow

1. **Connectivity Check**: Node checks health endpoint on each manager
2. **Token Retrieval**: Retrieves appropriate token from first responding manager
3. **Swarm Join**: Joins swarm using retrieved token and manager address
4. **Failover**: Automatically tries next manager if current fails

## Customization

### Adding a New Manager Node

```nix
# hosts/dock09.nix
modules.docker = {
  mode = "manager";
  manager-addrs = [ "10.0.1.30" ]; # Existing manager
  metrics-port = 9323;
};
```

### Adding a New Worker Node

```nix
# hosts/dock10.nix
modules.docker = {
  mode = "worker";
  manager-addrs = [
    "10.0.1.30"  # Primary manager
    "10.0.1.31"  # Additional managers
  ];
  metrics-port = 9323;
};
```

### Modifying Shared Services

All monitoring and shared services are in `modules/nixos/`:
- **prometheus.nix**: Node exporter configuration
- **promtail.nix**: Log shipping configuration
- **tailscale.nix**: VPN configuration

Changes to these modules affect all hosts.

## GitHub Actions (Future)

The plan is to:
1. Run `nix flake check` on every push
2. Automatically trigger deployments on specific hosts when their configs change
3. Use GitHub Actions to validate all configurations

## Secrets Management

Currently secrets are embedded in the flake. Consider:
- Using `sops-nix` for secrets management
- Using `agenix` for age-encrypted secrets
- Using environment variables or external secret stores

## Monitoring Stack

- **Prometheus**: Metrics collection
- **Loki**: Log aggregation (loki.svc.w0lf.io)
- **Grafana**: Visualization
- **Node Exporter**: Host metrics (port 9100)
- **Promtail**: Log shipping (port 9080)
- **Docker Metrics**: Container metrics (port 9323)

## Network Layout

### Network Interfaces
- **ens18**: Primary network interface (DHCP)
- **docker0**: Docker bridge network
- **docker_gwbridge**: Docker swarm network

### Port Usage
- **2377/tcp**: Docker Swarm management
- **7946/tcp+udp**: Container network discovery
- **4789/udp**: Overlay network traffic
- **3505/tcp**: Swarm token distribution API (managers only)
- **9323/tcp**: Docker metrics exporter
- **9100/tcp**: Node exporter metrics
- **9080/tcp**: Promtail metrics

## Troubleshooting

### Docker Swarm Issues

#### Swarm not joining
```bash
# Check swarm setup service
systemctl status docker-swarm-setup
journalctl -u docker-swarm-setup -n 50

# Check current swarm status
docker info | grep -A 5 "Swarm:"

# Test manager connectivity manually
curl -v http://MANAGER_IP:3505/health
curl -v http://MANAGER_IP:3505/swarm/worker
```

#### Manager token webserver issues
```bash
# Check if webserver is running (on manager)
curl http://localhost:3505/health
curl http://localhost:3505/swarm/manager
curl http://localhost:3505/swarm/worker

# Check swarm tokens are available
docker swarm join-token worker
docker swarm join-token manager
```

#### Network connectivity issues
```bash
# Test manager reachability (no ping dependency)
curl --connect-timeout 5 http://MANAGER_IP:3505/health

# Check firewall ports
ss -tulpn | grep :3505
ss -tulpn | grep :2377
```

### Service Status Checks

#### Monitoring services
```bash
systemctl status promtail
journalctl -u promtail -n 50
curl http://localhost:9080/ready
```

#### Network services
```bash
systemctl status tailscale-autoconnect
tailscale status
```

## License

[Your License Here]
