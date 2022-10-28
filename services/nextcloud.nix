{ pkgs, ... }:
{
  imports = [
    <sops-nix/modules/sops>
  ];

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud24;
    hostName = "nextcloud.thetwins.xyz";
    https = true;
    autoUpdateApps.enable = false;
    extraAppsEnable = true;
    extraApps = {
      twofactor_totp = pkgs.fetchNextcloudApp {
        name = "twofactor_totp";
        sha256 = "59ad8feada69ef92310ac4c6e01e4343cfa24f347bca32818b864305cbfe00e2";
        url = "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v6.4.1/twofactor_totp-v6.4.1.tar.gz";
        version = "6.4.1";
      };
    };
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
