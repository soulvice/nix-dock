{
  inputs,
  lib,
  pkgs,
  pkgs-stable,
  ...
}:
let
  system = "x86_64-linux";
  legacy = pkgs.legacyPackages.${system};

  pre-commit = inputs.pre-commit-hooks.lib.${system}.run {
    src = ../.;
    hooks = {
      nixfmt-rfc-style.enable = true;
      prettier.enable = true;
      ruff.enable = true;
    };
  };
in
{
  checks.${system}.pre-commit-check = pre-commit;

  devShells.${system}.default = legacy.mkShell {
    inherit (pre-commit) shellHook;
    packages = with legacy; [
      bashInteractive
      nixfmt-rfc-style
      nodePackages.prettier
      ruff
    ];
    buildInputs = pre-commit.enabledPackages;
  };
}
