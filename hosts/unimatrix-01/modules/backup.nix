{ pkgs, config, ... }: {
  config.services.borgbackup.repos = {
    nextcloud = {
      user = "nextcloud";
      group = "nextcloud";
      quota = "1T";
      path = "/backup/nextcloud";
      authorizedKeys = map (key: key.path) config.services.openssh.hostKeys;
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
}
