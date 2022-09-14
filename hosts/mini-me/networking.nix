{ config, pkgs, ... }:
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

  systemd.services.freedns = {
    enable = true;
    description = "FreeDNS dynamic DNS updates";
    path = [ pkgs.curl ];
    script = "curl -sS $(cat /run/secrets/freedns/url)";
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      User = config.users.users.freedns.name;
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    startAt = "*-*-* *:0..59/15:00";
  };

  systemd.timers.freedns = {
    timerConfig.RandomizedDelaySec = 30;
  };
}