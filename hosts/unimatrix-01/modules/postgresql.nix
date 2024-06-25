{ pkgs, ... }:
{
  services.postgresql = {
    package = pkgs.postgresql_16;
    settings = {
      max_connections = 124;
      shared_buffers = "512MB";
      effective_cache_size = "3GB";
      maintenance_work_mem = "64MB";
      wal_buffers = "16MB";
      wal_level = "minimal";
      max_wal_senders = 0;
      checkpoint_timeout = "30min";
      checkpoint_completion_target = "0.9";
      wal_compression = "lz4";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
    };
  };
}