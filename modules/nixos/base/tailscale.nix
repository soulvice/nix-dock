{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:

{
  # Tailscale Configuration
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    openFirewall = true;
    extraSetFlags = [
      "--hostname=${config.networking.hostName}"
      "--report-posture"
    ];
    extraUpFlags = [
      "--reset"
      "--accept-routes"
      "--accept-dns=false"
      "--ssh"
    ];
    interfaceName = "tailscale0";
    disableTaildrop = true;
    authKeyFile = "${config.age.secrets.tailscale-auth-key.path}";
  };
}
