{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, sops-nix, ... }:
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
            sops-nix.nixosModules.sops
            ./tailscale.nix
          ];
        };
        plex = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/plex.nix
            sops-nix.nixosModules.sops
            ./tailscale.nix
          ];
        };
        unifi = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/unifi.nix
            sops-nix.nixosModules.sops
            ./tailscale.nix
          ];
        };
      };
    };
}


