{ config, ... }:
with builtins;
{
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
    signal = {
      enable = true;
      relayHosts = [ "thetwins.xyz" ];
    };
    relay.enable = true;
  };

  services.borgmatic.configurations.rustdesk = {
    source_directories = [
      "/var/lib/private/rustdesk/id_ed25519"
      "/var/lib/private/rustdesk/id_ed25519.pub"
    ];
    repositories = [
      {
        label = "services repository";
        path = "ssh://${config.services.borgbackup.repos.services.user}@localhost:${toString (head config.services.openssh.ports)}/${config.services.borgbackup.repos.services.path}";
      }
    ];
    ssh_command =
      let
        ed25519key = head (filter (key: key.type == "ed25519") config.services.openssh.hostKeys);
      in
      "ssh -i ${ed25519key.path}";
    archive_name_format = "{hostname}-rustdesk-{now:%Y-%m-%dT%H:%M:%S.%f}";
    keep_within = "1H";
    keep_secondly = 0;
    keep_minutely = 0;
    keep_hourly = 0;
    keep_daily = 7;
    keep_weekly = 4;
    keep_monthly = 6;
    keep_yearly = 2;
    checks = [
      {
        name = "repository";
        frequency = "1 month";
      }
      {
        name = "archives";
        frequency = "1 month";
      }
    ];
  };
}
