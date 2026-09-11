{
  inputs,
  config,
  home-network-lib,
  ...
}:
let
  btrfs-options = [
    "defaults"
    "noatime"
    "nodiscard"
    "barrier"
  ];
  xfs-options = [
    "defaults"
    "noatime"
    "nodiscard"
  ];
  vfat-options = [
    "defaults"
    "noatime"
  ];
in
{
  boot = {
    # remove when nixos-hardware has a binary cache
    kernelPackages =
      let
        crossPkgs = home-network-lib.remote-builders.fastest-crossPkgs config;
        rpi4-kernel =
          crossPkgs.callPackage (inputs.nixos-hardware.outPath + "/raspberry-pi/common/kernel.nix")
            {
              rpiVersion = 4;
            };
      in
      crossPkgs.linuxPackagesFor rpi4-kernel;

    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
  hardware.deviceTree = {
    enable = true;
    # to prevent build failure with compute module 4 trees
    filter = "bcm2711-rpi-4*.dtb";
    overlays = [
      {
        name = "gpio-fan-overlay";
        dtsFile = ./gpio-fan-overlay.dts;
      }
    ];
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
      options = vfat-options;
    };
    "/databases" = {
      device = "/dev/disk/by-label/databases";
      fsType = "xfs";
      options = xfs-options;
    };
    "/vault" = {
      device = "/dev/mapper/vault";
      fsType = "btrfs";
      options = btrfs-options;
      encrypted = {
        enable = true;
        label = "vault";
        keyFile = "/sysroot/secrets/vault.key";
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
    defaults.monitored = "-a -s S/../.././04";
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
    extraOptions = [ "--savestates=/var/lib/smartd/" ];
  };

  systemd = {
    # allow root rescue shell even if root password is disabled
    services.rescue.environment.SYSTEMD_SULOGIN_FORCE = "1";
    tmpfiles.rules = [
      "d /var/lib/smartd 750 root root - -"
    ];
  };
}
