{ ... }:
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

  unimatrix-01.backups.rustdesk = {
    source_directories = [
      "/var/lib/private/rustdesk/id_ed25519"
      "/var/lib/private/rustdesk/id_ed25519.pub"
    ];
  };
}
