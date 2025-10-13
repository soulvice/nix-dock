{ pkgs, ... }:{
  environment.systemPackages =  with pkgs; [
    parted
    dig
    nfs-utils
    prometheus
    promtail
    htop
    btop
  ];
}