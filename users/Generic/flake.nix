{
  description = "Configuration for user Generic";

  outputs = { self }: {
    nixosModules = {
      user = { pkgs, config, ... }: {
        config.users.users.Generic = {
          description = "Eric Wolf";
          isNormalUser = true;
          hashedPassword = "$6$F4ieJt04sAGLopYY$2xyRz3l/NikIZhAHy97hx12uQl8aXmQ9mCC2qe/idDJJ.qUheiVRHpvdDe0R/6eQ.qnOKmKyNjhkf4dFB9w8Y0";
          shell = pkgs.bashInteractive;
          createHome = true;
          openssh.authorizedKeys.keyFiles = [
            ./Generic.pub
          ];
        };
      };
      adminUser = { pkgs, config, ... }: {
        config = {
          users.users.Generic = {
            extraGroups = [ "wheel" ];
            packages = with pkgs; [
              bashInteractive
              nano
              git
              strace
              iotop
              rsync
              smartmontools
              borgbackup
            ];
          };
          nix.settings.trusted-users = [ "Generic" ];
        };
      };
      default = self.nixosModules.user;
    };
  };
}