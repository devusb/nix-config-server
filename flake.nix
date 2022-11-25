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
    blocky-tailscale = {
      url = "github:devusb/blocky-tailscale";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-generators, sops-nix, blocky-tailscale, ... }@inputs:
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
        blocky-fly =
          let
            system = "x86_64-linux";
            pkgs = legacyPackages.${system};
          in
          blocky-tailscale.packages.${system}.blocky-tailscale.override {
            blockyConfig = pkgs.writeText "blocky.conf" (builtins.toJSON (import ./blocky-fly/blocky-config.nix { }));
          };
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
            ./modules/tailscale-autoconnect.nix
            ./modules/tailscale-serve.nix
            ./modules/deploy-backup.nix
            ./modules/atuin.nix
          ];
        };

        plex = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./lxc/plex.nix
          ];
        };
        arr = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./lxc/arr.nix
          ];
        };
        unifi = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./lxc/unifi.nix
          ];
        };
        atuin = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./lxc/atuin.nix
          ];
        };
        fileshare = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./lxc/template.nix
            ./lxc/fileshare.nix
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


