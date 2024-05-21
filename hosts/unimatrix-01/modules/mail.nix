{ config, ... }:
with builtins;
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
    dmarcReporting = {
      enable = true;
      domain = "thetwins.xyz";
      localpart = "postmaster";
      organizationName = "The Twins";
    };
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

  services.fail2ban = {
    enable = true;
    jails = {
      postfix-sasl = ''
        enabled = true
        port = smtp,465,submission,imap,imaps,pop3,pop3s
        filter = postfix[mode=auth]
        maxretry = 3
        bantime = 600
      '';
      dovecot = ''
        enabled = true
        port = pop3,pop3s,imap,imaps,submission,465,sieve
        filter = dovecot[mode=normal]
        maxretry = 3
        bantime = 600
      '';
    };
  };

  services.borgmatic.configurations.mail = {
    source_directories = [
      config.mailserver.mailDirectory
      config.mailserver.sieveDirectory
      config.mailserver.dkimKeyDirectory
      "/var/lib/rspamd"
      "/var/lib/redis-rspamd/dump.rdb"
    ];
    exclude_patterns = [
      "${config.mailserver.mailDirectory}/*/*/tmp"
      "${config.mailserver.mailDirectory}/*/*/dovecot-uidlist.lock"
      "/var/lib/rspamd/*.hs"
      "/var/lib/rspamd/*.hsmp"
      "/var/lib/rspamd/*.map"
    ];
    repositories = [
      {
        label = "services repository";
        path = "ssh://${config.services.borgbackup.repos.services.user}@localhost:${toString (head config.services.openssh.ports)}/${config.services.borgbackup.repos.services.path}";
      }
    ];
    ssh_command = let ed25519key = head (filter (key: key.type == "ed25519") config.services.openssh.hostKeys); in "ssh -i ${ed25519key.path}";
    source_directories_must_exist = true;
    archive_name_format = "{hostname}-mail-{now:%Y-%m-%dT%H:%M:%S.%f}";
    keep_within = "1H";
    keep_secondly = 0;
    keep_minutely = 0;
    keep_hourly = 0;
    keep_daily = 7;
    keep_weekly = 4;
    keep_monthly = 6;
    keep_yearly = 2;
    checks = [
      {
        name = "repository";
        frequency = "1 month";
      }
      {
        name = "archives";
        frequency = "1 month";
      }
    ];
  };
}