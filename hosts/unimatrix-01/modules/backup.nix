{
  config,
  pkgs,
  lib,
  ...
}:
with builtins;
{
  options.unimatrix-01.backups =
    with lib.types;
    let
      settingsFormat = pkgs.formats.yaml { };
      cfgType = submodule { freeformType = settingsFormat.type; };
    in
    lib.mkOption {
      description = "Borgmatic Backup configurations";
      default = { };
      type = attrsOf cfgType;
    };

  config =
    let
      cfg = config.unimatrix-01.backups;
    in
    {
      services.borgbackup.repos = {
        services = {
          quota = "1T";
          path = "/backup/services";
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9rXxTIWesncym2GYnqLFGpT6QmOVKVKETEFuMb2TCm root@mini-me"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB10VjrUY7gSy7XD+IQ2uUwi6wNLdl24hBYs75sfNsoX Services"
          ];
        };
        deric-pc = {
          quota = "1.5T";
          path = "/backup/deric-pc";
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7A3AwVDW2qQ+xCTKuxp8xTnTVQhMqAF/k6PItnLHDP RPI"
          ];
        };
        werwolf-pc = {
          quota = "1.5T";
          path = "/backup/werwolf-pc";
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDDPLl2bUjJnxkSD5C2ATOGJYsevbfdPr/p0vi4obN5l wolf@esprimo-mx"
          ];
        };
      };

      services.borgmatic = {
        enable = cfg != { };
        configurations =
          let
            repo = config.services.borgbackup.repos.services;
            ed25519key = head (filter (key: key.type == "ed25519") config.services.openssh.hostKeys);
            ssh_port = head config.services.openssh.ports;
            mkCfg =
              name: cfg:
              lib.mkMerge [
                {
                  repositories = [
                    {
                      label = "services";
                      path = "ssh://${repo.user}@localhost:${toString ssh_port}/${repo.path}";
                    }
                  ];
                  ssh_command = lib.strings.escapeShellArgs [
                    (lib.getExe pkgs.openssh)
                    "-i"
                    ed25519key.path
                  ];
                  archive_name_format = "{hostname}-${name}-{now:%Y-%m-%dT%H:%M:%S.%f}";
                  source_directories_must_exist = true;
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
                }
                cfg
              ];
          in
          lib.mapAttrs mkCfg cfg;
      };

      systemd.services.borgmatic.serviceConfig = {
        ProtectSystem = "strict";
        ReadWritePaths = [
          "/backup"
          "${config.users.users.root.home}/.config/borg"
          "${config.users.users.root.home}/.cache/borg"
          "${config.users.users.root.home}/.borgmatic"
        ];
      };

      # make updates start predictably
      systemd.timers.borgmatic.timerConfig = {
        OnCalendar = [
          "" # override default
          "*-*-* 04:00:00"
        ];
        RandomizedDelaySec = "0";
        Persistent = false;
      };
    };
}
