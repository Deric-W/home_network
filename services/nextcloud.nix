{ pkgs, ... }:
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud25;
    hostName = "nextcloud.thetwins.xyz";
    https = true;
    autoUpdateApps.enable = false;
    extraAppsEnable = true;
    extraApps = {
      twofactor_totp = pkgs.fetchNextcloudApp {
        sha256 = "189cwq78dqanqxhsl69dahdkh230zhz2r285lvf0b7pg0sxcs0yc";
        url = "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v6.4.1/twofactor_totp-v6.4.1.tar.gz";
      };
      calendar = pkgs.fetchNextcloudApp {
        sha256 = "0xhrpadzz73rdjyk4y1xm5hwc6k104rlpp9nmw08pq8phpfs12qa";
        url = "https://github.com/nextcloud-releases/calendar/releases/download/v4.3.3/calendar-v4.3.3.tar.gz";
      };
      contacts = pkgs.fetchNextcloudApp {
        sha256 = "1rdql3m7pg9m044hppyrm3xw329y8h0pzwcmpcinjbjs0vqjssxk";
        url = "https://github.com/nextcloud-releases/contacts/releases/download/v5.2.0/contacts-v5.2.0.tar.gz";
      };
      maps = pkgs.fetchNextcloudApp {
        sha256 = "04mgk4g2262m3xkyrskq66vq8784pvv183ff1h3d6yilpy4ysjfy";
        url = "https://github.com/nextcloud/maps/releases/download/v1.0.2/maps-1.0.2.tar.gz";
      };
      forms = pkgs.fetchNextcloudApp {
        sha256 = "1hjdwhhx5p9n185b5v0vbxhnarcm83r52hsqq7qwfcfpy86axafr";
        url = "https://github.com/nextcloud/forms/releases/download/v3.2.0/forms.tar.gz";
      };
    };
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud/adminpass";
      defaultPhoneRegion = "DE";
    };
  };

  sops.secrets = {
    "nextcloud/adminpass" = {
      owner = "nextcloud";
      reloadUnits = [ "nextcloud-setup.service" ];
      sopsFile = ../secrets/nextcloud.yaml;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "nextcloud.thetwins.xyz" = {
        forceSSL = true;
        enableACME = true;
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }
    ];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "127.0.0.0/8"
      "8.8.8.8"
    ];
    jails = {
      nextcloud = ''
        enabled = true
        port = 80,443
        filter = nextcloud[journalmatch=_SYSTEMD_UNIT=phpfpm-nextcloud.service]
        maxretry = 3
        bantime = 600
      '';
    };
  };
  environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
    [INCLUDES]
    before = common.conf
    after = nextcloud.local

    [Definition]
    _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
    failregex = ^%(__prefix_line)s\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
    datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
  '';
}
