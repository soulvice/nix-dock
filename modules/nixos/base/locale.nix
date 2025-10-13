{ config, lib, pkgs, ... }:

{
  # Time
  time = {
    timeZone = lib.mkDefault "Australia/Brisbane";
  };

  # Language
  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_TIME = "en_AU.UTF-8";
    };
  };
}