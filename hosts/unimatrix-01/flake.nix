{
  description = "RPI4 home server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      sops-nix,
      nixos-mailserver,
    }@inputs:
    {
      nixosConfigurations."unimatrix-01" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          home-network-lib = import ../../lib { inherit nixpkgs; };
        };
        modules = [
          ./configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          sops-nix.nixosModules.sops
          nixos-mailserver.nixosModule
          ../../services/sshd.nix
          ../../modules/remote-builders.nix
          ../../modules/users/Generic/adminUser.nix
        ];
      };
    };
}
