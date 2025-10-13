{ ... }: {
  imports = [
    ./docker.nix
    ./nfs.nix
    ./metrics.nix
    ./promtail.nix
    ./users.nix
    ./networking.nix
    ./swarm-manager.nix
  ];
}