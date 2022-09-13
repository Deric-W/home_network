{ pkgs, ... }:
{
  imports = [
    <nixos-hardware/raspberry-pi/4>
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      "cma=128M"
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
      fsType = "ext4";
      options = [ "defaults" "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType="vfat";
      options = [ "defaults" "noatime" ];
    };
    "/var" = {
      device = "/dev/disk/by-label/data";
      fsType = "ext4";
      options = [ "defaults" "noatime" ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
      options = [ "defaults" ];
    }
  ];
}