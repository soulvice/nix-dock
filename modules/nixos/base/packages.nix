{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [

    # Metrics
    prometheus
    promtail

    # Disk
    parted
    nfs-utils

    # Diagnostics
    htop
    btop
    dig

    # Editing
    vim
  ];
}
