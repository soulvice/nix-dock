{ ... }:
{
  imports = [
    ./nfs.nix
    ./packages.nix
    ./metrics.nix
    ./promtail.nix
    ./users.nix
  ];
}
