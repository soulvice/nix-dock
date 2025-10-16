{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

{
  # Hostname from parameter
  networking.hostName = hostname;

  # Network Configuration (can be overridden per host)
  networking.useDHCP = lib.mkDefault false;

  # Timeservers
  networking.timeServers = [
    "10.0.0.1"
  ];

  # Firewall configuration for Docker Swarm + Monitoring
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
    ];
  };
}
