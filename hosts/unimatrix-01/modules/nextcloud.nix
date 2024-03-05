{ pkgs, config, ... }:
with builtins;
{
  config = {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud28;
      hostName = "nextcloud.thetwins.xyz";
      https = true;
      maxUploadSize = "3G";
      fastcgiTimeout = 300;
      autoUpdateApps.enable = false;
      extraAppsEnable = true;
      extraApps = {
        calendar = pkgs.fetchNextcloudApp {
          sha256 = "18mi6ccq640jq21hmir35v2967h07bjv226072d9qz5qkzkmrhss";
          url = "https://github.com/nextcloud-releases/calendar/releases/download/v4.6.5/calendar-v4.6.5.tar.gz";
          license = "agpl3Plus";
        };
        contacts = pkgs.fetchNextcloudApp {
          sha256 = "0g6pbzm7bxllpkf9jqkrb3ys8xvbmayxc3rqwspalzckayjbz98m";
          url = "https://github.com/nextcloud-releases/contacts/releases/download/v5.5.2/contacts-v5.5.2.tar.gz";
          license = "agpl3Plus";
        };
        maps = pkgs.fetchNextcloudApp {
          sha256 = "0rs5cqn2saip7fmj71ww879iqsmmigf0fi6fdbqmdxmrmvsnl9l6";
          url = "https://github.com/nextcloud/maps/releases/download/v1.3.1/maps-1.3.1.tar.gz";
          license = "agpl3Plus";
        };
        forms = pkgs.fetchNextcloudApp {
          sha256 = "0iqkwnadhi6i1gnx7wiqny862g25kfiqi2mgkaf5cyiig3rispa0";
          url = "https://github.com/nextcloud-releases/forms/releases/download/v4.1.1/forms-v4.1.1.tar.gz";
          license = "agpl3Plus";
        };
        polls = pkgs.fetchNextcloudApp {
          sha256 = "04y5g1vb9b9flya6557p0ychr5vnylzbgp2vcm7vhcsdbc5q9ib5";
          url = "https://github.com/nextcloud/polls/releases/download/v6.1.1/polls.tar.gz";
          license = "agpl3Plus";
        };
        notify_push = pkgs.fetchNextcloudApp {
          sha256 = "1inq39kdfynip4j9hfrgybiscgii7r0wkjb5pssvmqknbpqf7x4g";
          url = "https://github.com/nextcloud-releases/notify_push/releases/download/v0.6.9/notify_push-v0.6.9.tar.gz";
          license = "agpl3Plus";
        };
      };
      notify_push = {
        enable = true;
        bendDomainToLocalhost = true;
      };
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminuser = "admin";
        adminpassFile = config.sops.secrets."nextcloud/adminpass".path;
        defaultPhoneRegion = "DE";
      };
      caching.redis = true;
      extraOptions = {
        "memcache.local" = "\\OC\\Memcache\\Redis";
        "memcache.locking" = "\\OC\\Memcache\\Redis";
        redis = {
          host = config.services.redis.servers.nextcloud.unixSocket;
          port = 0;
          dbindex = 0;
        };
        mail_domain = "gmx.de";
        mail_from_address = "robo-eric";
        mail_smtphost = "mail.gmx.net";
        mail_smtpport = 587;
        mail_smtpsecure = "tls";
        mail_smtpauth = true;
        mail_smtpname = "robo-eric@gmx.de";
        mail_smtptimeout = 30;
        maintenance_window_start = 1;
      };
      phpOptions = {
        "opcache.interned_strings_buffer" = "16";
        "opcache.jit" = "tracing";
        "opcache.jit_buffer_size" = "128M";
      };
      poolSettings = {
        pm = "dynamic";
        "pm.max_children" = "32";
        "pm.max_requests" = "500";
        "pm.max_spare_servers" = "16";
        "pm.min_spare_servers" = "8";
        "pm.start_servers" = "8";
      };
      secretFile = config.sops.secrets."nextcloud/mailpass".path;
    };

    sops.secrets = {
      "nextcloud/adminpass" = {
        owner = "nextcloud";
        reloadUnits = [ "nextcloud-setup.service" ];
        sopsFile = ../../../secrets/nextcloud.yaml;
      };

      "nextcloud/mailpass" = {
        owner = "nextcloud";
        reloadUnits = [ "nextcloud-setup.service" ];
        sopsFile = ../../../secrets/nextcloud.yaml;
      };
    };

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        ${config.services.nextcloud.hostName} = {
          forceSSL = true;
          enableACME = true;
        };
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ config.services.nextcloud.config.dbname ];
      ensureUsers = [
        {
          name = config.services.nextcloud.config.dbuser;
          ensureDBOwnership = true;
        }
      ];
      authentication = "
        local ${config.services.nextcloud.config.dbname} ${config.services.nextcloud.config.dbuser} peer map=nextcloud
      ";
      # allow root to log in as nextcloud to make backups
      identMap = "
        nextcloud root ${config.services.nextcloud.config.dbuser}
        nextcloud nextcloud ${config.services.nextcloud.config.dbuser}
      ";
    };

    systemd.services."nextcloud-setup" = {
      requires = [ "postgresql.service" "redis-nextcloud.service" ];
      after = [ "postgresql.service" "redis-nextcloud.service" ];
    };

    services.redis.servers.nextcloud = {
      enable = true;
      user = "nextcloud";
      save = [];
      databases = 1;
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
                  ^%(__prefix_line)s\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
      datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
    '';

    services.borgmatic.configurations.nextcloud = {
      source_directories = [
        "${config.services.nextcloud.home}/config"
        "${config.services.nextcloud.home}/data"
      ];
      repositories = [
        {
          label = "services repository";
          path = "ssh://${config.services.borgbackup.repos.services.user}@localhost:${toString (head config.services.openssh.ports)}/${config.services.borgbackup.repos.services.path}";
        }
      ];
      ssh_command = let ed25519key = head (filter (key: key.type == "ed25519") config.services.openssh.hostKeys); in "ssh -i ${ed25519key.path}";
      source_directories_must_exist = true;
      archive_name_format = "{hostname}-nextcloud-{now:%Y-%m-%dT%H:%M:%S.%f}";
      keep_within = "1H";
      keep_secondly = 0;
      keep_minutely = 0;
      keep_hourly = 0;
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      keep_yearly = 2;
      checks = [
        {
          name = "repository";
          frequency = "1 month";
        }
        {
          name = "archives";
          frequency = "1 month";
        }
      ];
      before_backup = [ "nextcloud-occ maintenance:mode --on" ];
      after_backup = [ "nextcloud-occ maintenance:mode --off" ];
      postgresql_databases = [{
        name = config.services.nextcloud.config.dbname;
        hostname = config.services.nextcloud.config.dbhost;
        username = config.services.nextcloud.config.dbuser;
        no_owner = true;
      }];
    };
    systemd.services.borgmatic = {
      wants = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
      # allow to execute nextcloud-occ (which in turn executes sudo)
      path = config.environment.systemPackages;
      serviceConfig.CapabilityBoundingSet = "CAP_SETUID CAP_SETGID";
    };
  };
}
