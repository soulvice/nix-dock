{ ... }:
{

  # NETWORK INTERFACES
  # ens18 - Management NIC (tagged vlan10)
  # ens19 - Untagged NIC used for network communication for services.
  #         VLan interfaces are created with ens19 as the parent (ie: ens19.40 for tagged 40)

  # Network Configuration
  networking.useDHCP = false;
  networking.interfaces.ens18 = {
    useDHCP = true;
  };
  networking.interfaces.ens19 = {
    useDHCP = false;
  };
}
