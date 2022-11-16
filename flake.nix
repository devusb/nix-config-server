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

  outputs = { nixpkgs, nixos-generators, sops-nix, ... }@inputs:
    let
      inherit (nixpkgs.lib) genAttrs;
      forAllSystems = genAttrs [ "x86_64-linux" "aarch64-linux" ];

      overlays = { default = import ./overlay { inherit inputs; }; };
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config.allowUnfree = true;
        }
      );
    in
    {
      formatter = forAllSystems (system: legacyPackages.${system}.nixpkgs-fmt);

      # images
      images = {
        proxmox-lxc = nixos-generators.nixosGenerate {
          modules = [
            ./lxc/template.nix
          ];
          pkgs = legacyPackages."x86_64-linux";
          format = "proxmox-lxc";
        };
        router = nixos-generators.nixosGenerate {
          modules = [
            ./router
          ];
          pkgs = legacyPackages."aarch64-linux";
          format = "sd-aarch64-installer";
        };
        blocky-fly = import ./blocky-fly { pkgs = legacyPackages."x86_64-linux"; };
      };

      # colmena targets
      colmena = {
        meta = {
          nixpkgs = legacyPackages."x86_64-linux";
          nodeNixpkgs = {
            router = legacyPackages."aarch64-linux";
          };
        };
        defaults = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            sops-nix.nixosModules.sops
          ];
        };

        plex = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./tailscale
            ./lxc/plex.nix
          ];
        };
        arr = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./tailscale
            ./lxc/arr.nix
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


