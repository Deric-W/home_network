{ pkgs, ... }:
{
  services.postgresql = {
    package = pkgs.postgresql_16;
    settings = {
      shared_buffers = "512MB";
    };
  };
}