{ pkgs, ... }:
let
  btrfs-options = [ "defaults" "noatime" "nodiscard" "barrier"];
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
    autodetect = true;
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
    };
  };
}
