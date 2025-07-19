{ inputs, lib, pkgs, ... }:
{
  imports = [
    ./modules/hardware.nix
    ./modules/networking.nix
    ./modules/acme.nix
    ./modules/secrets.nix
    ./modules/time.nix
    ./modules/backup.nix
    ./modules/nextcloud.nix
    ./modules/mail.nix
    ./modules/nginx.nix
    ./modules/postgresql.nix
    ./modules/fail2ban.nix
    ./modules/transmission.nix
    ./modules/shares.nix
  ];

  config = {
    system.stateVersion = "22.11";

    environment = {
      defaultPackages = [ ];
      systemPackages = with pkgs; [
        nano
        bashInteractive
        raspberrypi-eeprom
      ];
    };

    users.mutableUsers = false;

    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    };
  };
}
