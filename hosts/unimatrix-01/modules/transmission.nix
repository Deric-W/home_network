{ pkgs, config, ... }:
{
  config = {
    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openRPCPort = true;
      openPeerPorts = true;
      credentialsFile = config.sops.secrets.transmission.path;
      settings = {
        speed-limit-up-enabled = true;
        speed-limit-up = 3000;
        ratio-limit-enabled = false;
        rpc-bind-address = "0.0.0.0";
        rpc-authentication-required = true;
        rpc-username = "user";
        rpc-whitelist-enabled = false;
      };
    };

    # lower CPU and IO priority
    systemd.services.transmission.serviceConfig = {
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
      Nice = 19;
    };

    sops.secrets.transmission = {
      owner = config.services.transmission.user;
      group = config.services.transmission.group;
      restartUnits = [ "transmission" ];
      sopsFile = ../../../secrets/transmission.yaml;
    };
  };
}
