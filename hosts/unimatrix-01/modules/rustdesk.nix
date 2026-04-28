{ pkgs, lib, ... }:
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
    sqlite_databases =
      let
        sqliteCmd = lib.getExe pkgs.sqlite;
      in
      [
        {
          name = "main";
          path = "/var/lib/private/rustdesk/db_v2.sqlite3";
          sqlite_command = sqliteCmd;
          sqlite_restore_command = sqliteCmd;
        }
      ];
  };
}
