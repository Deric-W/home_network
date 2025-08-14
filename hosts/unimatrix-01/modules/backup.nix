{ ... }: {
  config = {
    services.borgbackup.repos = {
      services = {
        quota = "1T";
        path = "/backup/services";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9rXxTIWesncym2GYnqLFGpT6QmOVKVKETEFuMb2TCm root@mini-me"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB10VjrUY7gSy7XD+IQ2uUwi6wNLdl24hBYs75sfNsoX Services"
        ];
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
    services.borgmatic.enable = true;
    # make updates start predictably
    systemd.timers.borgmatic.timerConfig = {
      OnCalendar = [ "" "*-*-* 04:00:00" ];
      RandomizedDelaySec = "0";
      Persistent = false;
    };
  };
}
