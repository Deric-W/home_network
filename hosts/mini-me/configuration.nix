{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./network.nix
  ];

  system.stateVersion = "21.11";

  environment.systemPackages = with pkgs; [
    nano
    bashInteractive
    raspberrypi-eeprom
  ];

  services.openssh = {
    enable = true;
    banner = "Welcome to Mini Me\n";
    ports = [ 3724 ];
    openFirewall = false;   # handled by network.nix
    permitRootLogin = "no";
    passwordAuthentication = false;
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
      ];
    };
  };
}