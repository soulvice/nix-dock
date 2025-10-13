{ inputs, lib, pkgs, pkgs-stable, ... }:
let
  # Helper to create nixosSystem configurations
  mkHost = hostname: modules: inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs hostname;
      pkgs-stable = inputs.nixpkgs-stable.legacyPackages.x86_64-linux;
    };
    modules = [
      ../hosts/${hostname}.nix
    ] ++ modules;
  };

  # Host Config
  cConfig = name: addr: {
    inherit name addr;
  };

  # Docker Hosts
  dockerHosts = [ 
    (cConfig "dock01" "10.0.1.30")
    (cConfig "dock02" "10.0.1.31")
    (cConfig "dock03" "10.0.1.32")
    (cConfig "dock04" "10.0.1.33")
    (cConfig "dock05" "10.0.1.34")
    (cConfig "dock06" "10.0.1.35")
    (cConfig "dock07" "10.0.1.37")
    (cConfig "dock08" "10.0.1.38")
  ];

  storageHosts = [ 
    (cConfig "storage01" "10.0.1.10")
  ];

  allHosts = dockerHosts ++ storageHosts;

in {
  nixosConfigurations = builtins.listToAttrs (
    map (host: {
      name = host.name;
      value = mkHost host.name;
    }) allHosts
  );
}
