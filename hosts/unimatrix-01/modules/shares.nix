{ pkgs, config, ... }:
let
  sharesRoot = "/var/shares";
in
{
  services.samba = {
    enable = true;
    package = pkgs.samba;
    settings = {
      global = {
        "security" = "user";
        "valid users" = "+${config.users.groups."samba-users".name}";
        "unix password sync" = "no";
        "server role" = "standalone";
        "server min protocol" = "SMB3";
        "server smb encrypt" = "required";
        "server string" = "%h";
        "guest account" = config.users.users."samba-guest".name;
        "map to guest" = "Bad User";
        "log level" = "1 auth_audit:3";
        "logging" = "systemd";
        "load printers" = "no";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        "show add printer wizard" = "no";
      };
      scans = {
        "path" = "${sharesRoot}/scans";
        "comment" = "Netzlaufwerk für temporäre Scans";
        "valid users" = config.users.users."wolf-rudel".name;
        "browseable" = "yes";
        "guest ok" = "no";
        "writeable" = "yes";
        "printable" = "no";
        "create mask" = "0640";
        "directory mask" = "0750";
      };
    };
    smbd.enable = true;
    winbindd.enable = false;
    usershares.enable = false;
    nmbd.enable = false;
    nsswins = false;
    openFirewall = false;
  };

  users = {
    users."samba-guest" = {
      description = "Samba guest user";
      group = config.users.groups."samba-guest".name;
      extraGroups = [ config.users.groups."samba-users".name ];
      isSystemUser = true;
    };
    users."wolf-rudel" = {
      description = "Family account";
      group = config.users.groups."wolf-rudel".name;
      extraGroups = [ config.users.groups."samba-users".name ];
      isSystemUser = true;
    };
    groups = {
      "samba-users" = { };
      "${config.users.users."samba-guest".name}" = { };
      "${config.users.users."wolf-rudel".name}" = { };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${sharesRoot} 0755 root root - -"
    "d ${config.services.samba.settings.scans.path} 0750 ${config.users.users."wolf-rudel".name} ${
      config.users.users."wolf-rudel".group
    } - -"
  ];

  networking.firewall.allowedTCPPorts = [
    139
    445
  ];
}
