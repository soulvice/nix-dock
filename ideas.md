# Design Ideas

- I need a backup system for storage hosts which will be a module/file in saved in modules/storage/backup.nix
-

# Future Ideas

- The first/main manager will create the swarm
- It will then have a simple static webserver that when queried will respond with a swarm token.
  ie: - <swarm-manager-ip>/swarm/worker - response: { "token": "<swarm-worker-token>" } - <swarm-manager-ip>/swarm/manager - response: { "token": "<swarm-manager-token>" }
- The token is not cached or hardcoded but retrieved each call with `docker swarm join-token worker -q`
- This http server could run as a systemd service and can be stopped once all nodes are added
