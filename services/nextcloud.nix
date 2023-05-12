{ pkgs, ... }:
{
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
      calendar = pkgs.fetchNextcloudApp {
        name = "calendar";
        sha256 = "d6edc166d63204e39135c0e9f00c0f7a6875db89d34a936e16b513c749ac8b8d";
        url = "https://github.com/nextcloud-releases/calendar/releases/download/v3.5.2/calendar-v3.5.2.tar.gz";
        version = "3.5.2";
      };
      contacts = pkgs.fetchNextcloudApp {
        name = "contacts";
        sha256 = "1938b266c5070573e0435ec31c08a19add96fd99c08c3c1f8309ee8e447093a0";
        url = "https://github.com/nextcloud-releases/contacts/releases/download/v4.2.2/contacts-v4.2.2.tar.gz";
        version = "4.2.2";
      };
      maps = pkgs.fetchNextcloudApp {
        name = "maps";
        sha256 = "e9d4cd3461cabbdecb66f46f83be39d9ed9fc3eda5a14721b51bafdf5bcb2206";
        url = "https://github.com/nextcloud/maps/releases/download/v0.2.1/maps-0.2.1.tar.gz";
        version = "0.2.1";
      };
      forms = pkgs.fetchNextcloudApp {
        name = "forms";
        sha256 = "e8cd5fb59d6ae32394b0a0d101232620fb237a91f9011af643db3c9f541c04af";
        url = "https://github.com/nextcloud/forms/releases/download/v2.5.1/forms.tar.gz";
        version = "2.5.1";
      };
    };
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      adminuser = "admin";
      adminpassFile = "/run/secrets/nextcloud/adminpass";
      defaultPhoneRegion = "DE";
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
