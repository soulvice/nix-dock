{ config, pkgs, ... }: {
  # imports = [ inputs.nix-gaming.nixosModules.default ];
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://soulvice.cachix.org"
      ];
      trusted-public-keys = [
        "soulvice.cachix.org-1:fncdt9Eh48HqTGvBCBd+FfNba/EmYUKgaiiu3kQEwkU="
      ];
    };
    package = pkgs.nix;

    # Experimental Features
    extraOptions = ''
      experimental-features = nix-command flakes
      !include ${config.age.secrets.nix-access-tokens.path}
    '';

    # Garbage Collection
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  console.keyMap = "us";
  system.stateVersion = "25.05";
}
