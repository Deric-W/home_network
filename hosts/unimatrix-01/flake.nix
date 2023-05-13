{
  description = "RPI4 home server";

  inputs = {
    nixos-hardware.url = "nixos-hardware";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    generic.url = "../../users/Generic";
  };

  outputs = { self, nixpkgs, nixos-hardware, sops-nix, generic }: {
    nixosConfigurations."unimatrix-01" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        sops-nix.nixosModules.sops
        nixos-hardware.nixosModules.raspberry-pi-4
        generic.nixosModules.user
        generic.nixosModules.adminUser
        ../../services/freedns.nix
        ../../services/sshd.nix
      ];
    };
  };
}
