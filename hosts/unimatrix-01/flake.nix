{
  description = "RPI4 home server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    # unpin when updating to kernel 6.1
    nixos-hardware.url = "github:NixOS/nixos-hardware/b3a8d308a13390df35b198d4db36a654ec29e25a";
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
