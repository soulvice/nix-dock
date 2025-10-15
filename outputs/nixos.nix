{ inputs, lib, pkgs, pkgs-stable, ... }:
let

  # Host Config
  cConfig = hostname: addr: username: {
    inherit hostname addr username;
  };

  # Docker Hosts
  dockerHosts = [ 
    (cConfig "dock01" "10.0.1.30" "whale")
    (cConfig "dock02" "10.0.1.31" "whale")
    (cConfig "dock03" "10.0.1.32" "whale")
    (cConfig "dock04" "10.0.1.33" "whale")
    (cConfig "dock05" "10.0.1.34" "whale")
    (cConfig "dock06" "10.0.1.35" "whale")
    (cConfig "dock07" "10.0.1.37" "whale")
    (cConfig "dock08" "10.0.1.38" "whale")
  ];

  storageHosts = [ 
    (cConfig "storage01" "10.0.1.10" "hoarder")
  ];

  allHosts = dockerHosts ++ storageHosts;

in {
  nixosConfigurations = builtins.listToAttrs (
    map (host: {
      name = host.hostname;
      #value = mkHost host.name [] host.username;
      value = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit (inputs) mysecrets;
          inherit inputs;
          inherit (host) username hostname;
          pkgs-stable = inputs.nixpkgs-stable.legacyPackages.x86_64-linux;
          system-hosts = allHosts;
        };
        modules = [
          ../hosts/${host.hostname}.nix
        ];
      };
    }) allHosts
  );
}
