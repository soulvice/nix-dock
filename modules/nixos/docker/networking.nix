{ config, lib, hostname, ... }:
{
  # NETWORK INTERFACES
  # ens18 - Management NIC (tagged vlan10)
  # ens19 - Untagged NIC used for network communication for services.
  #         VLan interfaces are created with ens19 as the parent (ie: ens19.40 for tagged 40)

  networking = {
    useDHCP = false;

    macvlans = lib.mkIf (hostname == "dock01") {
      macvlan-mgmt = {
        interface = "ens18";
        mode = "bridge";
      };
    };

    dhcpcd.runHook = lib.mkIf (hostname == "dock01") ''
      if [ "$interface" = "ens18" ] && [ "$reason" = "BOUND" -o "$reason" = "REBIND" -o "$reason" = "RENEW" ]; then
        ip route replace 10.0.0.0/23 dev macvlan-mgmt
        ip route replace fd0a:0:1::/64 dev macvlan-mgmt
      fi
    '';

    dhcpcd.extraConfig = lib.mkIf (hostname == "dock01") ''
      denyinterfaces macvlan-mgmt
    '';

    interfaces = lib.mkMerge [

      # Management interface for dock01
      (lib.mkIf (hostname == "dock01") {
        macvlan-mgmt = {
          ipv4.addresses = [{ address = "10.0.0.254"; prefixLength = 32; }];
          ipv6.addresses = [{ address = "fd0a:0:1::fffe"; prefixLength = 128; }];
        };
      })

      # base networking configuration for all hosts
      {
        ens18 = {
          useDHCP = true;
        };

        ens19 = {
          useDHCP = false;
        };
      }
    ];
  };
}