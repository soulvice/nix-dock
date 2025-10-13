{ config, ... }:{
  # User Configuration
  users.users.hoarder = {
    isNormalUser = true;
    description = "Storage Admin";
    extraGroups = [ "wheel" "networkmanager" "systemd-journal" ];
    hashedPassword = "!";
    createHome = true;
    openssh.authorizedKeys.keyFiles = [
      "${config.age.secrets.ssh-key-storage.path}"
    ];
  };
}