{ pkgs, config, ... }: {
  config.services.borgbackup.repos = {
    nextcloud = {
      user = "nextcloud";
      group = "nextcloud";
      quota = "1T";
      path = "/backup/nextcloud";
      authorizedKeys = map (key: key.path) config.services.openssh.hostKeys;
    };
  };
}
