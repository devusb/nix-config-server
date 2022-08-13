{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-22.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nixos-generators, sops-nix, ... }:
    let overlay = import ./overlay { inherit nixpkgs; };
    in
    {
      packages.x86_64-linux = {
        proxmox-lxc = nixos-generators.nixosGenerate {
          modules = [
            ./lxc/template.nix
          ];
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          format = "proxmox-lxc";
        };
        router = nixos-generators.nixosGenerate {
          modules = [
            ./router
          ];
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          format = "sd-aarch64-installer";
        };
      };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ overlay ];
          };
          nodeNixpkgs = {
            aws-proxy = import nixpkgs-stable { system = "x86_64-linux"; overlays = [ overlay ]; };
            router = import nixpkgs { system = "aarch64-linux"; overlays = [ overlay ]; };
          };
        };
        defaults = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            sops-nix.nixosModules.sops
          ];
        };

        blocky = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./tailscale
            ./lxc/blocky.nix
          ];
        };
        plex = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./tailscale
            ./lxc/plex.nix
          ];
        };
        unifi = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./tailscale
            ./lxc/unifi.nix
          ];
        };
        aws-proxy = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./aws-proxy
          ];
        };
        router = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./router/colmena.nix
            ./router
          ];
        };
      };
    };
}


