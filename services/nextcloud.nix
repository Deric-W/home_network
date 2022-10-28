{ pkgs, ... }:
{
  imports = [
    <sops-nix/modules/sops>
  ];

  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.thetwins.xyz";
    https = true;
    autoUpdateApps.enable = false;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud/adminpass";
    };
  };

  sops.secrets = {
    "nextcloud/adminpass" = {
      owner = "nextcloud";
      reloadUnits = [ "nextcloud-setup.service" ];
      sopsFile = ../secrets/nextcloud.yaml;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "nextcloud.thetwins.xyz" = {
        forceSSL = true;
        enableACME = true;
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }
    ];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
