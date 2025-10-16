{ inputs, lib, pkgs, pkgs-stable, ... }:
let

  # Host Config
  cConfig = hostname: addr: username: {
    inherit hostname addr username;
  };

  wNode = hostname: addr: username: 
    (cConfig hostname addr username) // {
      mode = "worker";
    };

  mNode = hostname: addr: username:
    (cConfig hostname addr username) // {
      mode = "manager";
    };

  # Docker Hosts
  dockerHosts = [ 
    (mNode "dock01" "10.0.1.30" "whale")
    (wNode "dock02" "10.0.1.31" "whale")
    (wNode "dock03" "10.0.1.32" "whale")
    (wNode "dock04" "10.0.1.33" "whale")
    (wNode "dock05" "10.0.1.34" "whale")
    (wNode "dock06" "10.0.1.35" "whale")
    (mNode "dock07" "10.0.1.37" "whale")
    (mNode "dock08" "10.0.1.38" "whale")
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
          { nixpkgs.config.allowUnfree = true; }
          ../hosts/${host.hostname}.nix
        ];
      };
    }) allHosts
  );
}
