{ config, lib, ... }:
with builtins;
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

    # DNSSEC validation fails and a warning is produced after being turned off for an extended period of time
    # fixable by running date -s
    services.kresd =
    let
      forwardInterfaces = [ "127.0.0.1@53" ] ++ (lib.optional config.networking.enableIPv6 "::1@53");
      recursiveInterfaces = [ "127.0.0.1@1053" ] ++ (lib.optional config.networking.enableIPv6 "::1@1053");
      mkListen = interface: let 
        parts = match "^([^@]+)@(.+)$" interface;
        addr = elemAt parts 0;
        port = elemAt parts 1;
      in "net.listen('${addr}', ${port}, { kind = 'dns' })\n";
      negativeTrustAnchors = [
        "openstreetmap.org"
      ];
    in {
      enable = true;
      listenPlain = [];
      instances = 0;
      extraConfig = ''
        cache.size = 64 * MB

        local negativeTrustAnchors = {${lib.concatMapStringsSep ", " (domain: "'${domain}'") negativeTrustAnchors}}
        for _, negativeTrustAnchor in pairs(trust_anchors.insecure) do
          table.insert(negativeTrustAnchors, negativeTrustAnchor)
        end
        trust_anchors.set_insecure(negativeTrustAnchors)

        modules = { 'hints > iterate' }
        hints.add_hosts('/etc/hosts')
        policy.add(policy.domains(policy.PASS, {todname('localhost')}))

        local systemd_instance = os.getenv("SYSTEMD_INSTANCE")
        if string.match(systemd_instance, "^forward") then
            policy.add(policy.all(policy.FORWARD({'192.168.0.1', '8.8.8.8', '8.8.4.4'})))
            ${lib.concatMapStrings mkListen forwardInterfaces}
        elseif string.match(systemd_instance, "^recursive") then
            ${lib.concatMapStrings mkListen recursiveInterfaces}
        else 
            panic("use kresd@forward* for kresd@recursive* as instance names")
        end
      '';
    };
    systemd.targets.kresd.wants = [ "kresd@forward.service" "kresd@recursive.service" ];
  };
}
