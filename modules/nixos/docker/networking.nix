{ config, lib, hostname, ... }:
{
  # NETWORK INTERFACES
  # ens18 - Management NIC (tagged vlan10)
  # ens19 - Untagged NIC used for network communication for services.
  #         VLan interfaces are created with ens19 as the parent (ie: ens19.40 for tagged 40)

  networking = {
    useDHCP = false;

    interfaces = lib.mkMerge [
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