{ config, ... }:
with builtins;
{
  imports = [
    <sops-nix/modules/sops>
  ];

  config = {
    fileSystems."/secrets" = {
      device = "/dev/disk/by-label/secrets";
      fsType = "f2fs";
      neededForBoot = true;
      options = [ "defaults" "noatime" ];
    };

    services.openssh.hostKeys = [
      {
        bits = 4096;
        path = "${config.fileSystems."/secrets".mountPoint}/ssh_host_rsa_key";
        type = "rsa";
      }
      {
        path = "${config.fileSystems."/secrets".mountPoint}/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    sops.age = let ed25519Keys = filter (key: key.type == "ed25519") config.services.openssh.hostKeys; in {
      sshKeyPaths = map (key: key.path) ed25519Keys;
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };
}