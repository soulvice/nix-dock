{ config, lib, system-hosts, ... }: {

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = true;
    #authorizedKeysFiles = [
    #  "${config.age.secrets.ssh-key-docker.path}"
    #];
    #authorizedKeysFiles = lib.mkForce [
    #  "/etc/ssh/authorized_keys.d/%u"
    #];

    #knownHosts = builtins.listToAttrs (
    #  map (host: {
    #    name = host.hostname;
    #    value = {
    #      hostNames = [ host.hostname host.addr ];
    #      publicKeyFile = "${config.age.secrets.ssh-key-docker.path}";
    #    };
    #  }) system-hosts
    #);
  };

  # Add ssh hosts to each system so they can move stuff around
  #programs.ssh = let
  programs.ssh = {
  #  hosts = [ 
  #    { name = "dock01"; addr = "10.0.1.30"; }
  #    { name = "dock02"; addr = "10.0.1.31"; } 
  #    { name = "dock03"; addr = "10.0.1.32"; } 
  #    { name = "dock04"; addr = "10.0.1.33"; } 
  #    { name = "dock05"; addr = "10.0.1.34"; }
  #    { name = "dock06"; addr = "10.0.1.35"; }
  #    { name = "dock07"; addr = "10.0.1.37"; }
  #    { name = "dock08"; addr = "10.0.1.38"; } ];
  #in{
  #  knownHosts = builtins.listToAttrs (
  #    map (host: {
  #      name = host.name;
  #      value = {
  #        hostNames = [ host.name host.addr ];
  #        publicKeyFile = "${config.age.secrets.ssh-key-docker.path}";
  #      };
  #    }) hosts
  #  ) // {
  #    # Storage Host
  #  };
#
    extraConfig = lib.concatMapStrings (host: ''
      Host ${host.hostname}
        HostName ${host.addr}
        Port 22
        User whale
        IdentityFile /etc/ragenix/ssh-identity-key-docker
        StrictHostKeyChecking accept-new
    '') system-hosts;
  };

}
