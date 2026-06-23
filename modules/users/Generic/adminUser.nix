{ pkgs, ... }:
{
  imports = [
    ./user.nix
  ];
  config = {
    users.users.Generic = {
      extraGroups = [ "wheel" ];
      packages = with pkgs; [
        git
        usbutils
        util-linux
        htop
        iotop
        smartmontools
        strace
        dig
        rsync
        borgbackup
        borgmatic
      ];
    };
    nix.settings.trusted-users = [ "Generic" ];
  };
}
