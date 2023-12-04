{ pkgs, config, ... }:
{
  config = {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud27;
      hostName = "nextcloud.thetwins.xyz";
      https = true;
      maxUploadSize = "3G";
      fastcgiTimeout = 300;
      autoUpdateApps.enable = false;
      extraAppsEnable = true;
      extraApps = {
        calendar = pkgs.fetchNextcloudApp {
          sha256 = "0d6mfqwq44z9kn8nh3zmfzr05zi2rwnw3nhd9wc12dy6npynkcpm";
          url = "https://github.com/nextcloud-releases/calendar/releases/download/v4.6.0/calendar-v4.6.0.tar.gz";
          license = "agpl3Plus";
        };
        contacts = pkgs.fetchNextcloudApp {
          sha256 = "1pz2px5amk3byn4pq86cyyjv4hrqhsjz61xfm7cl7z8qfckqfhi2";
          url = "https://github.com/nextcloud-releases/contacts/releases/download/v5.4.2/contacts-v5.4.2.tar.gz";
          license = "agpl3Plus";
        };
        maps = pkgs.fetchNextcloudApp {
          sha256 = "1rcmqnm5364h5gaq1yy6b6d7k17napgn0yc9ymrnn75bps9s71v9";
          url = "https://github.com/nextcloud/maps/releases/download/v1.1.1/maps-1.1.1.tar.gz";
          license = "agpl3Plus";
        };
        forms = pkgs.fetchNextcloudApp {
          sha256 = "0nh1pigk4swrhh13b61m23jgpzclx3cdqapx9532yzfc58k3m5fk";
          url = "https://github.com/nextcloud-releases/forms/releases/download/v3.4.2/forms-v3.4.2.tar.gz";
          license = "agpl3Plus";
        };
        polls = pkgs.fetchNextcloudApp {
          sha256 = "1dmws4ybv3pzxz5g9c7ghblx0nfal2ssmsg7hjcs1n4xcjc6585p";
          url = "https://github.com/nextcloud/polls/releases/download/v5.4.2/polls.tar.gz";
          license = "agpl3Plus";
        };
        notify_push = pkgs.fetchNextcloudApp {
          sha256 = "0lwyy1pnyfw464vab1v5k8q0rgarrj5w12cf1nsywjaafb8y1ym0";
          url = "https://github.com/nextcloud-releases/notify_push/releases/download/v0.6.5/notify_push-v0.6.5.tar.gz";
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

    # cant use borgbackup.jobs since we need to backup the DB and the files
    users.users.nextcloud.createHome = true;
    systemd.services."borgbackup-jobs-nextcloud" =
      let
        userHome = config.users.users.nextcloud.home;
      in
      {
        description = "Borgbackup job nextcloud (custom)";
        path = [ pkgs.borgbackup ] ++ config.environment.systemPackages;
        script = ''
          on_exit()
          {
            exitStatus=$?
            nextcloud-occ maintenance:mode --off
            exit $exitStatus
          }

          if ! borg list > /dev/null; then
            borg init --encryption none --storage-quota 1T
          fi

          trap on_exit EXIT
          nextcloud-occ maintenance:mode --on

          home_archive="${config.networking.hostName}-nextcloud-home-$(date "+%Y-%m-%dT%H:%M:%S")"
          borg create \
            --compression lz4 \
            "::''${home_archive}.failed" \
            ${config.services.nextcloud.home}/config \
            ${config.services.nextcloud.home}/data

          borg rename \
            "::''${home_archive}.failed" \
            "$home_archive"

          set -o pipefail
          export PGPASSWORD="$(cat ${config.services.nextcloud.config.adminpassFile})"
          db_archive="${config.networking.hostName}-nextcloud-db-$(date "+%Y-%m-%dT%H:%M:%S")"
          pg_dump ${config.services.nextcloud.config.dbname} \
            -h ${config.services.nextcloud.config.dbhost} \
            -U ${config.services.nextcloud.config.dbuser} \
            --no-password \
          | borg create \
            --compression lz4 \
            --files-cache disabled \
            "::''${db_archive}.failed" \
            -
          borg rename \
            "::''${db_archive}.failed" \
            "$db_archive"

          nextcloud-occ maintenance:mode --off
          trap - EXIT
        
          borg prune \
            --glob-archives "${config.networking.hostName}-nextcloud-home-*" \
            --keep-within 1H \
            --keep-daily 7 \
            --keep-weekly 4 \
            --keep-monthly 6 \
            --keep-yearly 2

          borg prune \
            --glob-archives "${config.networking.hostName}-nextcloud-db-*" \
            --keep-within 1H \
            --keep-daily 7 \
            --keep-weekly 4 \
            --keep-monthly 6 \
            --keep-yearly 2

          borg compact
        '';
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
        startAt = "*-*-* 04:00:00";
        environment = {
          BORG_REPO = "/backup/nextcloud";
        };
        serviceConfig = {
          User = "nextcloud";
          Group = "nextcloud";
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
          ProtectSystem = "strict";
          PrivateTmp = true;
          ReadWritePaths = [
            config.services.nextcloud.home
            config.services.nextcloud.datadir
            "${userHome}/.config/borg"
            "${userHome}/.cache/borg"
            "/backup/nextcloud"
          ];
        };
      };
    system.activationScripts."borgbackup-jobs-nextcloud" =
      let
        install = "install -o nextcloud -g nextcloud";
      in
      ''
        cd "${config.users.users.nextcloud.home}"
        ${install} -d .config .config/borg
        ${install} -d .cache .cache/borg
        ${install} -d /backup/nextcloud
      '';
  };
}
