{ config, lib, pkgs, ... }: let
  cfg = config.modules.runner;
in {
  options.modules.runner = {
    enable = lib.mkEnableOption "Enable runner";
  };


  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      services.github-runners = {
        default = {
          enable = true;
          replace = true;
          user = "whale";
          group = "docker";
          ephemeral = true;
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
            gawk        # ← awk
            gnugrep     # ← grep
            coreutils   # ← cp, mkdir, chmod etc.
            bash
            curl
          ];
          serviceOverrides = {
            ReadWritePaths = [ "/docker" "/tmp" ];
            ProtectSystem  = lib.mkForce "full";   # downgrade from strict
          };
        };
      };

      # Add runner to docker group so it can call docker without owning directories
      users.users.github-runner-default.isSystemUser = true;
      users.users.github-runner-default.group = "github-runner-default";
      users.groups.github-runner-default = {};
      users.users.github-runner-default.extraGroups = [ "docker" ];
    })
  ];
}
