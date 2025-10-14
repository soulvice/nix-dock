{ config, ... }:{
  # User Configuration
  users.users.whale = {
    isNormalUser = true;
    description = "Whale Docker Admin";
    extraGroups = [ "wheel" "docker" "networkmanager" "systemd-journal" ];
    hashedPassword = "!";
    createHome = true;
    #openssh.authorizedKeys.keyFiles = [
    #  "${config.age.secrets.ssh-key-docker.path}"
    #];
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.hashedPassword = "!";
}