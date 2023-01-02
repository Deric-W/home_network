{ pkgs, ... }:
{
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      wall.enable = true;
    };
  };
}
