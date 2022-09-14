{ config, ... }:
with builtins;
let
  hostname = "mini-me";
in {
  networking = {
    hostName = hostname;
    defaultGateway = "192.168.0.1";
    nameservers = [ "8.8.8.8" ];
    interfaces.eth0 = {
      ipv4.addresses = [{
        address = "192.168.0.8";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fd00:3a10:d5ff:febc:ffff:dead:beef:fff";
        prefixLength = 64;
      }];
    };
    firewall = {
      enable = true;
      allowedTCPPorts = concatLists [
        config.services.openssh.ports
      ];
    };
  };
}