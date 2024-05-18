{
  description = "RPI4 home server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    generic.url = "../../users/Generic";
  };

  outputs = { self, nixpkgs, nixos-hardware, sops-nix, nixos-mailserver, generic }: {
    nixosConfigurations."unimatrix-01" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        nixos-hardware.nixosModules.raspberry-pi-4
        sops-nix.nixosModules.sops
        nixos-mailserver.nixosModule
        generic.nixosModules.user
        generic.nixosModules.adminUser
        ../../services/freedns.nix
        ../../services/sshd.nix
      ];
    };
  };
}
