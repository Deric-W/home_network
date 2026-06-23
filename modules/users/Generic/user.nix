{ pkgs, ... }:
{
  config.users.users.Generic = {
    description = "Eric Wolf";
    isNormalUser = true;
    hashedPassword = "$6$F4ieJt04sAGLopYY$2xyRz3l/NikIZhAHy97hx12uQl8aXmQ9mCC2qe/idDJJ.qUheiVRHpvdDe0R/6eQ.qnOKmKyNjhkf4dFB9w8Y0";
    shell = pkgs.bashInteractive;
    createHome = true;
    openssh.authorizedKeys.keyFiles = [
      ./key.pub
    ];
    packages = with pkgs; [
      bashInteractive
      coreutils-full
      nano
    ];
  };
}
