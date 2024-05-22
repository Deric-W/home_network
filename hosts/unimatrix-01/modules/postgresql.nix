{ ... }:
{
  services.postgresql = {
    settings = {
      shared_buffers = "512MB";
    };
  };
}