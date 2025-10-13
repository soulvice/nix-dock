{
  lib,
  config,
  pkgs,
  inputs,
  mysecrets,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.secrets;

  #username = "whale"; # This needs to be changed to dynamic users

  enabledServerSecrets =
    cfg.server.docker.enable
    || cfg.server.storage.enable;

  noaccess = {
    mode = "0000";
    owner = "root";
  };
  high_security = {
    mode = "0500";
    owner = "root";
  };
  user_readable = {
    mode = "0500";
    owner = username;
  };
in
{
  imports = [
    inputs.ragenix.nixosModules.default
  ];

  options.modules.secrets = {
    server.docker.enable = mkEnableOption "NixOS Secrets for Docker Servers";
    server.storage.enable = mkEnableOption "NixOS Secrets for Storage Servers";
    preservation.enable = mkEnableOption "whether use preservation and ephemeral root file system";
  };

  config = mkIf (enabledServerSecrets) (mkMerge [
    {
      environment.systemPackages = [
        inputs.ragenix.packages."${pkgs.system}".default
      ];

      # if you changed this key, you need to regenerate all encrypt files from the decrypt contents!
      age.identityPaths =
        if cfg.preservation.enable then
          [
            # To decrypt secrets on boot, this key should exists when the system is booting,
            # so we should use the real key file path(prefixed by `/persistent/`) here, instead of the path mounted by preservation.
            "/persist/etc/ssh/ssh_host_ed25519_key" # Linux
          ]
        else
          [
            "/etc/ssh/ssh_host_ed25519_key"
          ];

      # secrets that are used by all nixos hosts
      age.secrets = {
        "nix-access-tokens" =
          {
            file = "${mysecrets}/nix-access-tokens.age";
          }
          # access-token needs to be readable by the user running the `nix` command
          // user_readable;

        "tailscale-auth-key" = {
          file = "${mysecrets}/tailscale_auth_key.age";
        } // high_security;
      };

      assertions = [
        {
          # This expression should be true to pass the assertion
          assertion = !(cfg.docker.enable && cfg.storage.enable);
          message = "Enable either docker or storage secrets, not both!";
        }
      ];
    }

    (mkIf cfg.docker.enable {
      age.secrets = {
        # ---------------------------------------------
        # user can read this file.
        # ---------------------------------------------

        "ssh-key-docker" = {
          file = "${mysecrets}/ssh-key-docker.age";
        } // user_readable;

        "ssh-identity-key-docker" = {
          file = "${mysecrets}/ssh-key-docker.age";
        } // user_readable;

      };

      # place secrets in /etc/
      environment.etc = {
        "/ragenix/ssh-identity-key-docker" = {
          source = config.age.secrets."ssh-identity-key-docker".path;
          mode = "0600";
          user = username;
        };
      };
    })

    (mkIf cfg.storage.enable {
      age.secrets = {
        # ---------------------------------------------
        # user can read this file.
        # ---------------------------------------------

        "ssh-key-storage" = {
          file = "${mysecrets}/ssh-key-storage.age";
        } // user_readable;

      };

      # place secrets in /etc/
      environment.etc = {
        "/ragenix/ssh-key-storage" = {
          source = config.age.secrets."ssh-key-storage".path;
          mode = "0600";
          user = username;
        };
      };
    })
  ]);
}
