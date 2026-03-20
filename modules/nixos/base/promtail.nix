{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:
let

  cfg = config.modules.metrics.promtail;

in
{
  # OPTIONS ========================
  options.modules.metrics = {
    promtail = {
      enable = lib.mkEnableOption "Enable Promtail" // {
        default = true;
      };
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
	    timeout = "30s";
	    batchwait = "5s";
	    batchsize = 1048576;
            backoff_config = {
	      min_period = "500ms";
	      max_period = "5m";
	      max_retries = 10;
	    };
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

    # Promtail might be starting before DNS is fully started
    systemd.services.promtail = with lib; {
      after = [ "network-online.target" "nss-lookup.target" ];
      wants = [ "network-online.target" ];
      requires = [ "nss-lookup.target" ];
      
      serviceConfig = {
        Restart = mkForce "on-failure";
        RestartSec = mkForce "10s";
        TimeoutStartSec = mkForce "90s";
        TimeoutStopSec = mkForce "30s";  # Fix the timeout on stop issue
        
        # Network access
        PrivateNetwork = mkForce false;
        RestrictAddressFamilies = mkForce [ "AF_INET" "AF_INET6" "AF_UNIX" ];
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
    users.groups.promtail = { };
  };
}
