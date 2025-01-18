{ config, ... }:
{
  config = {
    users.groups = {
      "acme-thetwins" = {};
      "acme-nextcloud-thetwins" = {};
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "robo-eric@gmx.de";
      };
      certs = {
        "thetwins.xyz".group = config.users.groups."acme-thetwins".name;
        "nextcloud.thetwins.xyz".group = config.users.groups."acme-nextcloud-thetwins".name;
      };
    };

    users.users.${config.services.nginx.user}.extraGroups = [
      config.security.acme.certs."thetwins.xyz".group
      config.security.acme.certs."nextcloud.thetwins.xyz".group
    ];
    services.nginx.virtualHosts = {
      "thetwins.xyz" = {
        enableACME = true;
        forceSSL = true;
      };
      "nextcloud.thetwins.xyz" = {
        enableACME = true;
        forceSSL = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}