{ pkgs, config, ... }:
{
  config = {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud26;
      hostName = "nextcloud.thetwins.xyz";
      https = true;
      maxUploadSize = "2G";
      autoUpdateApps.enable = false;
      extraAppsEnable = true;
      extraApps = {
        calendar = pkgs.fetchNextcloudApp {
          sha256 = "0pj1h86kdnckzfrn13hllgps4wa921z4s24pg5d2666fqx89rwrv";
          url = "https://github.com/nextcloud-releases/calendar/releases/download/v4.3.4/calendar-v4.3.4.tar.gz";
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
          sha256 = "0jfnidmx93k0z923m3p3bi8qv46j875cpnc60hlpxvcl35zbb2rl";
          url = "https://github.com/nextcloud-releases/forms/releases/download/v3.3.0/forms-v3.3.0.tar.gz";
        };
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
      };
    };

    sops.secrets = {
      "nextcloud/adminpass" = {
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
          ensurePermissions."DATABASE ${config.services.nextcloud.config.dbname}" = "ALL PRIVILEGES";
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
