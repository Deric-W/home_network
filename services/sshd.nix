{ pkgs, config, ... }:
with builtins;
{
  config = {
    services.openssh = {
      enable = true;
      ports = [ 3724 ];
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        Banner = (pkgs.writeText "ssh_banner" "Welcome to ${config.networking.hostName}\n").outPath;
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
