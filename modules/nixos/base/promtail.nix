{ config, pkgs, lib, hostname, ... }: let

  cfg = config.modules.metrics.promtail;

in{
  # OPTIONS ========================
  options.modules.metrics = {
    promtail = {
      enable = lib.mkEnableOption "Enable Promtail" // { default = true; };
      url = lib.mkOption {
        type = lib.types.str;
        description = "URL for logging collection service";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/var/log/promtail/positions.yaml";
        };

        clients = [
          {
            url = cfg.url;
          }
        ];

        scrape_configs = [
          # System journal logs
          {
            job_name = "systemd-journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = hostname;
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal__hostname" ];
                target_label = "hostname";
              }
              {
                source_labels = [ "__journal_priority_keyword" ];
                target_label = "level";
              }
              {
                source_labels = [ "__journal__comm" ];
                target_label = "command";
              }
            ];
          }

          # SSH logs
          {
            job_name = "sshd";
            journal = {
              matches = "_SYSTEMD_UNIT=sshd.service";
              labels = {
                job = "sshd";
                host = hostname;
              };
            };
          }
        ];
      };
    };

    # Ensure promtail log directory exists
    systemd.tmpfiles.rules = [
      "d /var/log/promtail 0755 promtail promtail -"
    ];

    # Give promtail access to systemd journal
    users.users.promtail = {
      isSystemUser = true;
      group = "promtail";
      extraGroups = [ "systemd-journal" ];
    };
    users.groups.promtail = {};
  };
}
