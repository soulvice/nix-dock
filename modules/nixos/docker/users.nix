{ config, username, ... }:
{
  # User Configuration
  users.users.${username} = {
    isNormalUser = true;
    description = "Whale Docker Admin";
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "systemd-journal"
    ];
    hashedPassword = "!";
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICTEcf9PnQ1sOEPiU4KF3lhAeS6niTVw8bM6YyB0mvfK docker-host 2026-05"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.hashedPassword = "!";
}
