{ config, lib, pkgs, ... }: let
  cfg = config.modules.runner;
in {
  options.modules.runner = {
    enable = lib.mkEnableOption "Enable runner";
  };


  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      services.github-runners = {
        instances.default = {
          enable = true;
          url = "https://github.com/soulvice/LimeWire";
          tokenFile = "${config.age.secrets."github-runner".path}";
          name = config.networking.hostName;
          extraLabels = [ config.networking.hostName "nixos" "docker" ];
          extraPackages = with pkgs; [
            docker
            docker-compose
            rsync
            jq
            git
          ];
        };
      };

      # Add runner to docker group so it can call docker without owning directories
      users.users.github-runner-default.extraGroups = [ "docker" ];
    })
  ];
}