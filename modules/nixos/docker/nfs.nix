{
  config,
  pkgs,
  lib,
  ...
}:
let

in
{
  # NFS Client for shared storage
  services.rpcbind.enable = true;

  environment.systemPackages = with pkgs; [
    nfs-utils
  ];
}
