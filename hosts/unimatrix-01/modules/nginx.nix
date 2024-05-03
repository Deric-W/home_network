{ ... }:
{
  config = {
    services.nginx = {
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      appendConfig = "worker_processes auto;";
    };
  };
}