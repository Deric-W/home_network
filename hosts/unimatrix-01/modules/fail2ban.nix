{ pkgs, ... }:
{
  services.fail2ban = {
    extraPackages = with pkgs; [ whois ];
    bantime = "10m";
    maxretry = 3;
    jails.DEFAULT.settings = {
      destemail = "generic@thetwins.xyz";
      mta = "sendmail";
      action = "%(action_mwl)s";
      findtime = "10m";
    };
    bantime-increment = {
      enable = true;
      maxtime = "24h";
    };
    ignoreIP = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };
  environment.etc."fail2ban/action.d/sendmail-common.local".text = ''
    [Definition]
    # don't send mail on startup
    actionstart =

    # don't send mail on shutdown
    actionstop =
  '';
}