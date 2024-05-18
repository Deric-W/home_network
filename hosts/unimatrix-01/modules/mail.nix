{ config, ... }:
{
  mailserver = {
    enable = true;
    domains = [ "thetwins.xyz" ];
    fqdn = "thetwins.xyz";
    enableImap = true;
    enableImapSsl = true;
    enableSubmission = true;
    enableSubmissionSsl = true;
    enableManageSieve = true;
    hierarchySeparator = "/";
    indexDir = "/var/lib/dovecot/indices";
    useUTF8FolderNames = true;
    localDnsResolver = false;   # handled by systemd-resolved
    openFirewall = true;
    loginAccounts = {
      "generic@thetwins.xyz" = {
        hashedPasswordFile = config.sops.secrets."dovecot/generic".path;
        quota = "10G";
        aliases = [ "abuse@thetwins.xyz" "postmaster@thetwins.xyz" ];
      };
    };
    certificateScheme = "acme";
    dkimSigning = true;
    dmarcReporting = {
      enable = true;
      domain = "thetwins.xyz";
      localpart = "postmaster";
      organizationName = "The Twins";
    };
  };

  services.rspamd.overrides."logging.inc".text = "level = \"notice\";";

  users.users.${config.services.postfix.user}.extraGroups = [ config.security.acme.certs."thetwins.xyz".group ];
  users.users.${config.services.dovecot2.user}.extraGroups = [ config.security.acme.certs."thetwins.xyz".group ];

  services.redis = {
    vmOverCommit = true;
    servers.rspamd = {
      enable = true;
      user = config.services.rspamd.user;
      port = 6380;
      save = [ 
        [ 3600 1 ]
        [ 60 1000 ]
      ];
      databases = 1;
    };
  };

  sops.secrets = {
    "dovecot/generic" = {
      owner = config.services.dovecot2.user;
      reloadUnits = [ "dovecot2.service" ];
      sopsFile = ../../../secrets/dovecot.yaml;
    };
  };
}