{ ... }:
{
  imports = [
    <sops-nix/modules/sops>
  ];

  sops.age = {
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    keyFile = "/var/lib/sops-nix/key.txt";
    generateKey = true;
  };

  sops.secrets = {
    "freedns/url" = {
      sopsFile = ./secrets/freedns.yaml;
    };
  };
}