# NixOS Docker Infrastructure Flake

Multi-host NixOS flake for managing Docker Swarm infrastructure with monitoring.

## Structure

```
.
├── flake.nix                    # Main flake entry point
├── outputs/                     # Output definitions
│   ├── nixos.nix               # Host configurations
│   ├── checks.nix              # Pre-commit hooks
│   └── ...
├── modules/nixos/              # Shared NixOS modules
│   ├── default.nix             # Common base configuration
│   ├── docker-host.nix         # Docker host configuration
│   ├── docker-host-gpu.nix     # GPU Docker host configuration
│   ├── storage-host.nix        # Storage host configuration
│   ├── prometheus.nix          # Node exporter monitoring
│   ├── promtail.nix            # Log shipping to Loki
│   ├── tailscale.nix           # Tailscale VPN
│   ├── nfs-client.nix          # NFS client mounts
│   ├── nfs-server.nix          # NFS server exports
│   └── ...
└── hosts/                      # Per-host hardware configurations
    ├── dock01/
    ├── dock02/                 # GPU host
    ├── dock03-08/
    └── storage01-03/
```

## Hosts

### Docker Hosts (8 total)
- **dock01, dock03-08** (7 hosts): Standard Docker Swarm workers
- **dock02** (1 host): GPU-enabled Docker Swarm worker

### Storage Hosts (3 total)
- **storage01-03**: NFS storage servers

## Features

### All Hosts
- ✅ Prometheus node_exporter for metrics
- ✅ Promtail for log shipping to Loki
- ✅ Tailscale for secure networking
- ✅ Automated SSH key management
- ✅ Common system packages

### Docker Hosts
- ✅ Docker with btrfs storage driver
- ✅ Docker Swarm auto-join
- ✅ NFS client mounts for shared storage
- ✅ Docker container log collection
- ✅ Automatic pruning

### GPU Docker Host (dock02)
- ✅ NVIDIA Docker runtime
- ✅ GPU metrics exporter
- ✅ NVIDIA container toolkit

### Storage Hosts
- ✅ NFS server with exports
- ✅ XFS filesystem monitoring
- ✅ SMART disk health monitoring
- ✅ Optimized kernel parameters for NFS

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

3. **Customize per-host settings:**
   - Update Docker Swarm tokens and manager IPs in host configs
   - Update Tailscale auth keys
   - Update SSH authorized keys
   - Update NFS server IPs in nfs-client.nix

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

## Customization

### Adding a New Docker Host

1. Create directory: `mkdir -p hosts/dock09`
2. Add hardware-configuration.nix
3. Add to `outputs/nixos.nix`:
   ```nix
   dock09 = mkHost "dock09" [ dockerHostModule ];
   ```

### Adding a New Storage Host

1. Create directory: `mkdir -p hosts/storage04`
2. Add hardware-configuration.nix with correct filesystem mounts
3. Add to `outputs/nixos.nix`:
   ```nix
   storage04 = mkHost "storage04" [ storageHostModule ];
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

- **Prometheus**: Metrics collection (10.0.1.x)
- **Loki**: Log aggregation (loki.svc.w0lf.io)
- **Grafana**: Visualization
- **Node Exporter**: Host metrics (port 9100)
- **Promtail**: Log shipping (port 9080)
- **Docker Metrics**: Container metrics (port 9323)

## Network Layout

- **ens18**: Primary network interface (DHCP)
- **ens19**: Secondary interface (not configured)
- **docker0**: Docker bridge network
- **docker_gwbridge**: Docker swarm network

## Troubleshooting

### Docker Swarm not joining
```bash
systemctl status docker-swarm-setup
journalctl -u docker-swarm-setup -n 50
```

### NFS mounts not working
```bash
systemctl status rpcbind
showmount -e 10.0.1.10
mount | grep nfs
```

### Promtail not shipping logs
```bash
systemctl status promtail
journalctl -u promtail -n 50
curl http://localhost:9080/ready
```

### Tailscale not connecting
```bash
systemctl status tailscale-autoconnect
tailscale status
```

## License

[Your License Here]
