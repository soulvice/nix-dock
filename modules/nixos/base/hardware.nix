{ config, lib, pkgs, ... }:

{
  # Bootloader for BIOS (can be overridden per host)
  boot.loader.grub = {
    enable = lib.mkDefault true;
    device = lib.mkDefault "/dev/sda";
  };
}