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
      "--hostname=${hostname}"
      "--ssh"
      "--accept-routes"
      "--accept-dns=false"
    ];
    interfaceName = "tailscale0";
    disableTaildrop = true;
    authKeyFile = "${config.age.secrets.tailscale-auth-key.path}";
  };
}
