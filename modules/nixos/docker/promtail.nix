{ config, lib, ... }:
let

  cfg = config.modules.metrics.promtail;

in
{

  config = lib.mkIf (cfg.enable) {
    # Docker containers with service discovery
    services.promtail.configuration.scrape_configs = [
      {
        job_name = "docker";
        docker_sd_configs = [
          {
            host = "unix:///var/run/docker.sock";
            refresh_interval = "5s";
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__meta_docker_container_name" ];
            regex = "/(.*)";
            target_label = "container";
          }
          {
            source_labels = [ "__meta_docker_container_image" ];
            target_label = "image";
          }
          {
            source_labels = [ "__meta_docker_container_id" ];
            target_label = "container_id";
          }
          {
            source_labels = [ "__meta_docker_container_log_stream" ];
            target_label = "stream";
          }
          {
            source_labels = [ "__meta_docker_swarm_service_name" ];
            target_label = "service";
          }
          {
            source_labels = [ "__meta_docker_stack_namespace" ];
            target_label = "stack";
          }
          {
            source_labels = [ "__meta_docker_swarm_node_hostname" ];
            target_label = "node";
          }
        ];
      }
    ];

    # Allow access for promtail to read docker.socket
    systemd.services.promtail.serviceConfig = {
      ReadOnlyPaths = [
        "/var/lib/docker/containers"
        "/var/run/docker.sock"
      ];
      SupplementaryGroups = [ "docker" ];
    };
  };
}
