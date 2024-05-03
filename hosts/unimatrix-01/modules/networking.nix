{ ... }:
{
  config = {
    networking = {
      hostName = "unimatrix-01";

      defaultGateway = {
        address = "192.168.0.1";
        interface = "eth0";
      };
      defaultGateway6 = {
        address = "fd00:3a10:d5ff:febc:3a10:d5ff:febc:d559";
        interface = "eth0";
      };

      useDHCP = false;

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

      firewall.enable = true;
    };

    # DNS caching
    services.resolved = {
      enable = true;
      fallbackDns = [
        "8.8.8.8"
        "8.8.4.4"
      ];
    };
  };
}
