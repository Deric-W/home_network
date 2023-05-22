{ ... }:
{
  config.hardware.printers = {
    ensurePrinters = [
      {
        name = "MFC-250C";
        location = "109";
        model = "raw";
        deviceUri = "usb://Brother/MFC-250C?serial=BROA9F180693";
      }
    ];
    ensureDefaultPrinter = "MFC-250C";
  };
  config.services.printing = {
    enable = true;
    browsing = true;
    defaultShared = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [
      "localhost"
      "192.168.0.*"
    ];
  };
  config.services.saned = {
    enable = true;
    extraConfig = ''
      192.168.0.0/24
    '';
  };
  config.networking.firewall = {
    allowedUDPPorts = [ 631 ];
    allowedTCPPorts = [ 631 6566 ];
  };
  config.services.avahi = {
    enable = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}
