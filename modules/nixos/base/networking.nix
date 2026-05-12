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

    # Was just 127.0.0.1
    nameservers =
      if hostname == "dock01" then
        [
          "10.0.1.2"
          "1.1.1.1"
        ]
      else
        [ "10.0.0.1" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    #resolveconf.useLocalresolver = lib.mkIf (hostname == "dock01") true;
  };

  #services.resolved.enable = if hostname == "dock01" then false else true;
  services.resolved = lib.mkIf (hostname != "dock01") {
    dnssec = lib.mkIf (hostname != "dock01") "false";
    extraConfig = ''
      DNS=10.0.1.2
      FallbackDNS=1.1.1.1 1.0.0.1
      DNSStubListener=yes
    '';
  };
  services.avahi = {
    enable = false;
    reflector = true;
    openFirewall = true;
    interfaces = [
      "ens18"
    ]
    ++ lib.optionals (lib.hasPrefix "dock" config.networking.hostName) [
      "ens19"
      "docker0"
    ];
  };

}
