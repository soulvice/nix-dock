{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

{

  networking = {
    hostName = hostname;

    useDHCP = lib.mkDefault false;

    timeServers = [ "10.0.0.1" ];

    nameservers = [ "10.0.0.1" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      ${if hostname == "dock01" then "DNS=127.0.0.1" else "DNS=10.0.0.1"}
      FallbackDNS=100.100.100.100
    '';
  };
}
