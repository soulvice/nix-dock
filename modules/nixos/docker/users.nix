{ config, username, ... }:{
  # User Configuration
  users.users.${username} = {
    isNormalUser = true;
    description = "Whale Docker Admin";
    extraGroups = [ "wheel" "docker" "networkmanager" "systemd-journal" ];
    hashedPassword = "!";
    createHome = true;
    openssh.authorizedKeys.keyFiles = [
      "/etc/ragenix/ssh-key-docker"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.hashedPassword = "!";
}
