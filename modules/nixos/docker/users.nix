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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkdrjnOfJgtdCbs6Ai4j0jghU4I9VhULKWS9ONOPmvw dadmin@nixbook"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.hashedPassword = "!";
}
