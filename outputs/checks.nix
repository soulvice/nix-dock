{ inputs, lib, pkgs, pkgs-stable, ... }:

let
  pre-commit = inputs.pre-commit-hooks.lib.x86_64-linux.run {
    src = ../.;
    hooks = {
      # Nix formatting
      nixpkgs-fmt = {
        enable = true;
      };

      # Nix linting
      statix = {
        enable = true;
      };

      # Dead code detection
      deadnix = {
        enable = true;
      };

      # Nix evaluation check
      nix-linter = {
        enable = false; # Can be enabled if nix-linter is needed
      };
    };
  };
in
{
  checks.x86_64-linux = {
    pre-commit-check = pre-commit;
  };

  # Development shell with pre-commit hooks
  devShells.x86_64-linux.default = pkgs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
    inherit (pre-commit) shellHook;
    buildInputs = pre-commit.enabledPackages ++ [
      pkgs.nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt
      pkgs.nixpkgs.legacyPackages.x86_64-linux.statix
      pkgs.nixpkgs.legacyPackages.x86_64-linux.deadnix
    ];
  };
}
