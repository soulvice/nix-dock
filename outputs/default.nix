{ self, nixpkgs, nixpkgs-stable, nixpkgs-unstable, pre-commit-hooks } @ inputs:
let
  inherit (inputs.nixpkgs) lib;

  sharedArgs = {
    inherit inputs lib;
    pkgs = inputs.nixpkgs;
    pkgs-stable = inputs.nixpkgs-stable;
  };

  nixosOutputs = import ./nixos.nix sharedArgs;
  packageOutputs = import ./packages.nix sharedArgs;
  devShells = import ./devshells.nix sharedArgs // { inherit self; };
  checks = import ./checks.nix sharedArgs;
  formatters = import ./formatters.nix (removeAttrs sharedArgs [ "lib" ]);

in nixosOutputs // packageOutputs // devShells // checks // formatters
