{ config, ... }:
{
  mailserver = {
    enable = true;
    stateVersion = 3;
    domains = [ "thetwins.xyz" ];
    systemDomain = "thetwins.xyz";
    systemName = "The Twins";
    fqdn = "thetwins.xyz";
    enableImap = true;
    enableImapSsl = true;
    enableSubmission = true;
    enableSubmissionSsl = true;
    enableManageSieve = true;
    hierarchySeparator = "/";
    indexDir = "/var/lib/dovecot/indices";
    useUTF8FolderNames = true;
    localDnsResolver = false;   # handled by networking
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
    dmarcReporting.enable = true;
  };

  services.rspamd.overrides = {
    "logging.inc".text = "level = \"notice\";";
    "options.inc".text = ''
      dns {
        nameserver = "master-slave:127.0.0.1:1053,127.0.0.1:53";
      }
    '';
  };
  systemd.services.rspamd = {
    wants = [ "kresd.target" ];
    after = [ "kresd.target" ];
  };

  users.users.${config.services.postfix.user}.extraGroups = [ config.security.acme.certs."thetwins.xyz".group ];
  users.users.${config.services.dovecot2.user}.extraGroups = [ config.security.acme.certs."thetwins.xyz".group ];

  services.redis = {
    vmOverCommit = true;
    servers.rspamd = {
      enable = true;
      user = config.services.rspamd.user;
      port = 0;
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
      group = config.services.dovecot2.group;
      reloadUnits = [ "dovecot.service" ];
      sopsFile = ../../../secrets/dovecot.yaml;
    };
    dkim = {
      owner = config.services.rspamd.user;
      group = config.services.rspamd.group;
      restartUnits = [ "rspamd.service" ];
      sopsFile = ../../../secrets/dkim.yaml;
      path = "${config.mailserver.dkimKeyDirectory}/thetwins.xyz.${config.mailserver.dkimSelector}.key";
    };
  };

  services.fail2ban = {
    enable = true;
    jails = {
      postfix-sasl.settings = {
        enabled = true;
        port = "smtp,465,submission,imap,imaps,pop3,pop3s";
        filter = "postfix[mode=auth]";
      };
      dovecot.settings = {
        enabled = true;
        port = "pop3,pop3s,imap,imaps,submission,465,sieve";
        filter = "dovecot[mode=normal]";
      };
    };
  };

  unimatrix-01.backups.mail = {
    source_directories = [
      config.mailserver.mailDirectory
      config.mailserver.sieveDirectory
      config.mailserver.dkimKeyDirectory
      "/var/lib/rspamd"
      "/var/lib/redis-rspamd/dump.rdb"
    ];
    exclude_patterns = [
      "${config.mailserver.mailDirectory}/*/*/mail/tmp"
      "${config.mailserver.mailDirectory}/*/*/mail/dovecot-uidlist.lock"
      config.sops.secrets.dkim.path
      "/var/lib/rspamd/*.hs"
      "/var/lib/rspamd/*.hsmp"
      "/var/lib/rspamd/*.map"
    ];
  };
}
