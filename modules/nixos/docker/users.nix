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
    #openssh.authorizedKeys.keyFiles = [
    #  "/etc/ssh/authorized_keys.d/${username}"
    #];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.hashedPassword = "!";
}
