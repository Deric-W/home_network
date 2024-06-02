{ pkgs, config, ... }:
with builtins;
{
  config = {
    services.openssh = {
      enable = true;
      banner = "Welcome to ${config.networking.hostName}\n";
      ports = [ 3724 ];
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    services.fail2ban = {
      enable = true;
      jails.sshd.settings = {
        enabled = true;
        port = concatStringsSep "," (map toString config.services.openssh.ports);
        filter = "sshd";
      };
    };
  };
}
