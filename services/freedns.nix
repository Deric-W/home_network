{ pkgs, config, ... }:
{
  imports = [
    <sops-nix/modules/sops>
  ];

  config = {
    users = {
      users.freedns = {
        isSystemUser = true;
        group = "freedns";
      };
      groups.freedns = {};
    };

    systemd.services.freedns = {
      enable = true;
      description = "FreeDNS dynamic DNS updates";
      path = [ pkgs.curl ];
      script = "xargs -n 1 < /run/secrets/freedns/urls curl -sS";
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        User = config.users.users.freedns.name;
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