{ config, lib, hostname, ... }:
{
  # NETWORK INTERFACES
  # ens18 - Management NIC (tagged vlan10)
  # ens19 - Untagged NIC used for network communication for services.
  #         VLan interfaces are created with ens19 as the parent (ie: ens19.40 for tagged 40)

  networking = {
    useDHCP = false;

    interfaces.ens18 = {
      useDHCP = true;
    };

    interfaces.ens19 = {
      useDHCP = false;
    };

    macvlans = lib.mkIf (hostname == "dock01") {
      macvlan-mgmt = {
        interface = "ens18";
        mode = "bridge";
      };
    };

    interfaces = lib.mkIf (hostname == "dock01") {
      macvlan-mgmt = {
        ipv4.addresses = [{ address = "10.0.0.254"; prefixLength = 32; }];
        ipv6.addresses = [{ address = "fd0a:0:1::fffe"; prefixLength = 128; }];
      };
    };
  };

  systemd.network.networks."40-macvlan-mgmt" = lib.mkIf (hostname == "dock01") {
    matchConfig.Name = "macvlan-mgmt";
    routes = [
      { routeConfig = { Destination = "10.0.0.0/23"; Scope = "link"; }; }
      { routeConfig = { Destination = "fd0a:0:1::/64"; Scope = "link"; }; }
    ];
  };
}