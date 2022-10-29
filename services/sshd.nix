{ pkgs, config, ... }:
with builtins;
{
  config = {
    services.openssh = {
      enable = true;
      banner = "Welcome to ${config.networking.hostName}\n";
      ports = [ 3724 ];
      openFirewall = true;
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
