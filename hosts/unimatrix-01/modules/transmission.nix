{ config, ... }:
{
  config = {
    services.transmission = {
      enable = true;
      openRPCPort = true;
      openPeerPorts = true;
      credentialsFile = config.sops.secrets.transmission.path;
      settings = {
        speed-limit-up-enabled = true;
        speed-limit-up = 5000;
        rpc-bind-address = "0.0.0.0";
        rpc-authentication-required = true;
      };
    };

    sops.secrets.transmission = {
      owner = config.services.transmission.user;
      group = config.services.transmission.group;
      restartUnits = [ "transmission" ];
      sopsFile = ../../../secrets/transmission.yaml;
    };
  };
}
