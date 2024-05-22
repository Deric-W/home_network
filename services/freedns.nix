{ pkgs, config, ... }:
{
  config = {
    users = {
      users.freedns = {
        isSystemUser = true;
        group = config.users.groups.freedns.name;
        description = "User running dynamic DNS updates";
      };
      groups.freedns = { };
    };

    systemd.services.freedns = {
      enable = true;
      description = "FreeDNS dynamic DNS updates";
      serviceConfig = {
        ExecStart = "xargs -n 1 -a \"${config.sops.secrets."freedns/urls".path}\" ${pkgs.curl}/bin/curl -sS";
        Type = "oneshot";
        Restart = "on-failure";
        User = config.users.users.freedns.name;
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        DevicePolicy = "closed";
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = "AF_INET AF_INET6";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
      };
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      startAt = "*-*-* *:0..59/15:00";
    };

    systemd.timers.freedns = {
      timerConfig.RandomizedDelaySec = 30;
    };

    sops.secrets = {
      "freedns/urls" = {
        owner = config.systemd.services.freedns.serviceConfig.User;
        reloadUnits = [ "freedns.service" ];
        sopsFile = ../secrets/freedns.yaml;
      };
    };
  };
}
