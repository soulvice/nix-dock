{
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:

let
  pre-commit = inputs.pre-commit-hooks.lib.x86_64-linux.run {
    src = ../.;
    hooks = {
      # Nix formatting
      nixfmt-rfc-style = {
        enable = true;
      };

      # General code formatting
      prettier = {
        enable = true;
      };

      # Python linting
      ruff = {
        enable = true;
      };
    };
  };
in
{
  checks.x86_64-linux = {
    pre-commit-check = pre-commit;
  };

  # Development shell with pre-commit hooks
  devShells.x86_64-linux.default = pkgs.legacyPackages.x86_64-linux.mkShell {
    inherit (pre-commit) shellHook;
    buildInputs = pre-commit.enabledPackages ++ [
      pkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style
      pkgs.legacyPackages.x86_64-linux.nodePackages.prettier
      pkgs.legacyPackages.x86_64-linux.ruff
    ];
  };
}
