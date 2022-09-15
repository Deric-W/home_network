{ pkgs, config, ... }:
with builtins;
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./secrets.nix
    ../../modules/time.nix
    ../../services/freedns.nix
  ];

  config = {
    system.stateVersion = "22.05";

    environment = {
      defaultPackages = [];
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
        ];
      };
    };

    nix.trustedUsers = [ "@wheel" ];

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    services.openssh = {
      enable = true;
      banner = "Welcome to Mini Me\n";
      ports = [ 3724 ];
      openFirewall = false;   # handled by network.nix
      permitRootLogin = "no";
      passwordAuthentication = false;
    };

    services.fail2ban = {
      enable = true;
      ignoreIP = [
        "127.0.0.0/8"
        "8.8.8.8"
      ];
      jails = {
        sshd = ''
        enabled = true
        port = ${concatStringsSep "," (map toString config.services.openssh.ports)}
        filter = sshd
        maxretry = 3
        bantime = 600
        '';
      };
    };
  };
}