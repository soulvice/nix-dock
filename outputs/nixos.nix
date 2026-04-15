{
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:
let

  # Host Config
  cConfig = hostname: addr: username: {
    inherit hostname addr username;
  };

  wNode =
    hostname: addr: username:
    (cConfig hostname addr username)
    // {
      mode = "worker";
      service = "docker";
    };

  mNode =
    hostname: addr: username:
    (cConfig hostname addr username)
    // {
      mode = "manager";
      service = "docker";
    };

  sNode =
    hostname: addr: username:
    (cConfig hostname addr username)
    // {
      mode = "storage";
      service = "storage";
    };

  # Docker Hosts
  dockerHosts = [
    # Core Docker Swarm Nodes
    (mNode "dock01" "10.0.1.30" "whale") # Manager
    (wNode "dock02" "10.0.1.31" "whale") # Worker + GPU
    (wNode "dock03" "10.0.1.32" "whale") # Worker
    (wNode "dock04" "10.0.1.33" "whale") # Worker
    (wNode "dock05" "10.0.1.34" "whale") # Worker
    (wNode "dock06" "10.0.1.35" "whale") # Worker
    (mNode "dock07" "10.0.1.37" "whale") # Manager
    (mNode "dock08" "10.0.1.38" "whale") # Manager

    # ex-unraid server
    (wNode "dock09" "10.0.1.39" "whale") # Worker + GPU
    (wNode "dock10" "10.0.1.40" "whale") # Worker
    (wNode "dock11" "10.0.1.41" "whale") # Worker
    (mNode "dock12" "10.0.1.42" "whale") # Manager
  ];

  storageHosts = [
    (sNode "storage01" "10.0.1.10" "hoarder") # Docker Compose Storage
    (sNode "storage02" "10.0.1.11" "hoarder") # Media Storage
  ];

  allHosts = dockerHosts ++ storageHosts;

in
{
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
