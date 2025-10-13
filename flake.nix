{

  description = "Multi-host NixOS flake with user and secret integration";
  outputs = inputs: import ./outputs inputs;
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    ragenix = {
      url = "github:soulvice/ragenix";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # PRIVATE ====================
    mysecrets = {
      url = "git+ssh://git@github.com/soulvice/nixdock-secrets.git?shallow=1&ref=main";
      flake = false;
    };
  };
}
