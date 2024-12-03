{ pkgs, ... }:
let
  btrfs-options = [ "defaults" "noatime" "nodiscard" "barrier" ];
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    initrd = {
      availableKernelModules = [ "usbhid" "usb_storage" ];
    };
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      "cma=128M"
      "boot.shell_on_fail"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.raspberry-pi."4".fkms-3d.enable = true;
  hardware.deviceTree = {
    enable = true;
    # to prevent build failure with compute module 4 trees
    filter = "bcm2711-rpi-4*.dtb";
    overlays = [{
      name = "gpio-fan-overlay";
      # modified https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/gpio-fan-overlay.dts
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "brcm,bcm2711";

          fragment@0 {
            target-path = "/";
            __overlay__ {
              fan0: gpio-fan@0 {
                compatible = "gpio-fan";
                gpios = <&gpio 12 0>;
                gpio-fan,speed-map = <0    0>,
                          <5000 1>;
                #cooling-cells = <2>;
              };
            };
          };

          fragment@1 {
            target = <&cpu_thermal>;
            __overlay__ {
              polling-delay = <2000>;	/* milliseconds */
            };
          };

          fragment@2 {
            target = <&thermal_trips>;
            __overlay__ {
              cpu_hot: trip-point@0 {
                temperature = <60000>;	/* (millicelsius) Fan started at 60°C */
                hysteresis = <10000>;	/* (millicelsius) Fan stopped at 50°C */
                type = "active";
              };
            };
          };

          fragment@3 {
            target = <&cooling_maps>;
            __overlay__ {
              map0 {
                trip = <&cpu_hot>;
                cooling-device = <&fan0 1 1>;
              };
            };
          };

          __overrides__ {
            gpiopin = <&fan0>,"gpios:4", <&fan0>,"brcm,pins:0";
            temp = <&cpu_hot>,"temperature:0";
            hyst = <&cpu_hot>,"hysteresis:0";
          };
        };
      '';
    }];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = btrfs-options;
    };
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
      options = [ "defaults" "noatime" ];
    };
    "/var" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = btrfs-options;
    };
    "/vault" = {
      device = "/dev/mapper/vault";
      fsType = "btrfs";
      options = btrfs-options;
      encrypted = {
        enable = true;
        label = "vault";
        keyFile = "/mnt-root/secrets/vault.key";
        blkDev = "/dev/disk/by-partlabel/vault";
      };
    };
    "/backup" = {
      device = "/dev/disk/by-label/backup";
      fsType = "btrfs";
      options = btrfs-options;
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
      options = [ "defaults" ];
    }
  ];

  services.fstrim.enable = true;

  services.btrfs.autoScrub.enable = true;

  services.smartd = {
    enable = true;
    autodetect = false;
    defaults.monitored = "-a -n standby,16,q -s S/../.././04";
    devices = [
      {
        device = "/dev/disk/by-label/root";
        options = "-d sat";
      }
      {
        device = "/dev/disk/by-label/backup";
        options = "-d sat";
      }
    ];
    notifications = {
      wall.enable = true;
      mail = {
        enable = true;
        recipient = "generic@thetwins.xyz";
      };
    };
  };
}
