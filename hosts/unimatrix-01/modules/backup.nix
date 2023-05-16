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
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHNb7KuePlcJXECNQuBg7NuIG57ixM9xjaqyMYEHtFTk2riKNfjUbKJFSU0hUYFCTM8V9+XXihtmHjyF1M8TW53+LRKYN5R8UKRaywuLZ/vX+m/MvVhAZCEQ2oXrUyJR37yLmDaNIswavRuhz6vUfmRF4ldAsbzGaOjMScM0aQDUsaivHmhqjgtOAUvh9FvxyW0JAE2nVCW7kQlfIQrJUXkjZnTPKASevzbMdEB9LUIlVFOivwesgMD1jQmP3/j8mIoIm6o3rQpwQl3Djn97wAogeIaDgWY6GWm1tl8PGLggl03Ocmx8bxM2+V8C260C152qKT6cWhtfelIQolSz/alcldSYU58QSM1hGIGDUPkm6F17JmDQaqlTzDg62NPMWesMGNqFlT8aWRhxVD7lIOSi0SmLveOUxQl0szixSnDzS2uXY0ww/Nyhn6UhC2YFgDU1NWpRxzvH9Br4akqGGwt3x2qOuJStbPlEOtvUT4zgq2gO+9xr4ZmFPPEYW3ASIAmq24o8ahRh61zVA8Toq0n+NqJD+ZddKnBw1kLfx5Ov9P1P0kaz0eU4+JSlgaIczUPnHwtYJHrg3gJ+E6KPKB5FIDYDIuaRUR1xrphDDvDphyIQVZZwpStru4LFtF1VF92yu3OUZIjbWDPl9AQ3Eo5bcG2Ymwe8NjWwx2q4C9Uw== robo-eric@gmx.de"
      ];
    };
  };
}