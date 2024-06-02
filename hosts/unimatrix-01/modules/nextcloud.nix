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
          sha256 = "0zm2a63f99q7n1qw2n3p4pk50j5v4q24vpgndk4nnvaz6c792rzg";
          url = "https://github.com/nextcloud-releases/calendar/releases/download/v4.7.4/calendar-v4.7.4.tar.gz";
          license = "agpl3Plus";
        };
        contacts = pkgs.fetchNextcloudApp {
          sha256 = "0xyrkr5p7xa8cn33kgx1hyblpbsdzaakpfm5bk6w9sm71a42688w";
          url = "https://github.com/nextcloud-releases/contacts/releases/download/v5.5.3/contacts-v5.5.3.tar.gz";
          license = "agpl3Plus";
        };
        maps = pkgs.fetchNextcloudApp {
          sha256 = "1gqms3rrdpjmpb1h5d72b4lwbvsl8p10zwnkhgnsmvfcf93h3r1c";
          url = "https://github.com/nextcloud/maps/releases/download/v1.4.0/maps-1.4.0.tar.gz";
          license = "agpl3Plus";
        };
        forms = pkgs.fetchNextcloudApp {
          sha256 = "1hwc7ra12nsr79xp8lkv3ip46bxxbjpaglb0a4k06ikfnzjaddny";
          url = "https://github.com/nextcloud-releases/forms/releases/download/v4.2.4/forms-v4.2.4.tar.gz";
          license = "agpl3Plus";
        };
        polls = pkgs.fetchNextcloudApp {
          sha256 = "1crs6fks9ywywyi3pnji49dxnry5vpcmd1x29y8anyp32ji2a35r";
          url = "https://github.com/nextcloud/polls/releases/download/v7.0.3/polls.tar.gz";
          license = "agpl3Plus";
        };
        notify_push = pkgs.fetchNextcloudApp {
          sha256 = "1w0nb74q5ishwsd9xhgjlp5ik159xjfp5i2cczi0fmwlb185n1ik";
          url = "https://github.com/nextcloud-releases/notify_push/releases/download/v0.6.11/notify_push-v0.6.11.tar.gz";
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
      caching = {
        apcu = true;
        redis = true;
      };
      extraOptions = {
        "memcache.local" = "\\OC\\Memcache\\APCu";
        "memcache.distributed" = "\\OC\\Memcache\\Redis";
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
        "apc.enable_cli" = "1";
        "apc.shm_segments" = "1";
        "apc.shm_size" = "32M";
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
        restartUnits = [ "nextcloud-setup.service" ];
        sopsFile = ../../../secrets/nextcloud.yaml;
      };

      "nextcloud/mailpass" = {
        owner = "nextcloud";
        restartUnits = [ "nextcloud-setup.service" ];
        sopsFile = ../../../secrets/nextcloud.yaml;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${config.services.nextcloud.hostName}.forceSSL = true;
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
      port = 0;
      save = [];
      databases = 1;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.fail2ban = {
      enable = true;
      jails.nextcloud.settings = {
        enabled = true;
        port = "http,https";
        filter = "nextcloud[journalmatch=_SYSTEMD_UNIT=phpfpm-nextcloud.service]";
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
        # defaults to unix domain socket
        # is concatenated with destination which leads to timeout
        #hostname = config.services.nextcloud.config.dbhost;
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
