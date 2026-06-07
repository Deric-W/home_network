{ lib, config, ... }:
with builtins;
{
  options.home-network.remote-builders = with lib.types; {
    enable = lib.mkOption {
      description = "Enable remote builders";
      default = false;
      type = bool;
    };
    substituters = lib.mkOption {
      description = "Setup the remote builders as substituters";
      default = true;
      type = bool;
    };
    sshKey = lib.mkOption {
      description = ''
        SSH key to use when connecting to remote builders.

        When not provided (or set to null) the ed25519
        host key will be used.
      '';
      default = null;
      type = nullOr str;
    };
  };

  config =
    let
      cfg = config.home-network.remote-builders;
      remote-builders = [
        {
          hostName = "192.168.0.7";
          system = "x86_64-linux";
          protocol = "ssh-ng";
          speedFactor = 2;
          supportedFeatures = [
            "kvm"
            "big-parallel"
          ];
          sshUser = "nixremote";
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUw0dGJHSk1maSsraENGTm9PRmR5MHY4OEMwK2lRWmtPNHJEUXFKdzZtWEIgcm9vdEBHZW5lcmljLVBDCg==";
          publicKey = "remote-builder:9FWTr1nU5SEUKz5fduOcqEHsh+bcY8p3Qf9Hehd3RGY=";
        }
      ];
      ed25519Keys = filter (key: key.type == "ed25519") config.services.openssh.hostKeys;
      sshKey = if cfg.sshKey == null then (head ed25519Keys).path else cfg.sshKey;
    in
    lib.mkIf cfg.enable {
      nix = {
        distributedBuilds = true;
        buildMachines = map (builder: {
          inherit (builder)
            hostName
            system
            protocol
            speedFactor
            supportedFeatures
            sshUser
            publicHostKey
            ;
          sshKey = sshKey;
        }) remote-builders;
        extraOptions = ''
          builders-use-substitutes = true
        '';
        settings = lib.mkIf cfg.substituters {
          substituters = map (
            builder:
            let
              sshUser = lib.strings.escapeURL builder.sshUser;
              hostName = lib.strings.escapeURL builder.hostName;
              sshKeyUrl = lib.strings.escapeURL sshKey;
              publicHostKey = lib.strings.escapeURL builder.publicHostKey;
            in
            "ssh-ng://${sshUser}@${hostName}?ssh-key=${sshKeyUrl}&base64-ssh-public-host-key=${publicHostKey}"
          ) remote-builders;
          trusted-public-keys = map (builder: builder.publicKey) remote-builders;
        };
      };
      assertions = [
        {
          assertion = (cfg.sshKey == null) -> (length ed25519Keys) == 1;
          message = "Multiple (or none) matching ssh host keys exist, please choose one";
        }
      ];
    };
}
