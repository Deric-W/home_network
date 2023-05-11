{ pkgs, config, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./secrets.nix
    ../../modules/time.nix
    ../../modules/acme.nix
    ../../services/sshd.nix
    ../../services/freedns.nix
    ../../services/nextcloud.nix
  ];

  config = {
    system.stateVersion = "22.05";

    environment = {
      defaultPackages = [ ];
      systemPackages = with pkgs; [
        nano
        bashInteractive
        raspberrypi-eeprom
      ];
    };

    users = {
      mutableUsers = false;
      users.Deric = {
        isNormalUser = true;
        hashedPassword = "$6$BpffeP.jPYZqkUlL$b6YDT3ix9sZRmPE6wkTLN6rQhcFatQ.PD5WEQOwC54Al/NKn/HHl0Dv8PoGpF5h5kkKNuz.2vB5J6ND3I5Ids1";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keyFiles = [
          ./authorized_keys/Deric.pub
        ];
        packages = with pkgs; [
          git
          strace
          iotop
          rsync
          smartmontools
        ];
      };
    };

    nix.trustedUsers = [ "@wheel" ];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
