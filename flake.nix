{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, ... }:
    let overlay = import ./overlay { inherit nixpkgs; };
    in
    {
      packages.x86_64-linux = {
        proxmox-lxc = nixos-generators.nixosGenerate {
          modules = [
            ./template
          ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          format = "proxmox-lxc";
        };
      };
      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ overlay ];
          };
        };
        blocky = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/blocky.nix
          ];
        };
        plex = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/plex.nix
          ];
        };
        unifi = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/unifi.nix
          ];
        };
      };
    };
}


