{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nix-config = {
      url = "github:devusb/nix-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    blocky-tailscale = {
      url = "github:devusb/blocky-tailscale";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    attic = {
      url = "github:zhaofengli/attic";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-generators, sops-nix, impermanence, blocky-tailscale, attic, ... }@inputs:
    let
      inherit (nixpkgs.lib) genAttrs;
      forAllSystems = genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      overlays = { default = import ./overlay { inherit inputs; }; };
      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config = {
            allowUnfree = true;
            nvidia.acceptLicense = true;
          };
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
        sophia = nixos-generators.nixosGenerate {
          modules = [
            ./hosts/sophia
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
            blockyConfig = pkgs.writeText "blocky.conf" (builtins.toJSON (import ./images/blocky-fly/blocky-config.nix { }));
          };
        gaia = nixos-generators.nixosGenerate {
          modules = [
            ./hosts/gaia
          ];
          pkgs = legacyPackages."aarch64-linux";
          format = "sd-aarch64-installer";
        };
        pomerium =
          let
            system = "x86_64-linux";
            pkgs = legacyPackages.${system};
          in
          pkgs.dockerTools.buildLayeredImage (import ./images/pomerium pkgs);
      };

      # colmena targets
      colmena = {
        meta = {
          nixpkgs = legacyPackages."x86_64-linux";
          nodeNixpkgs = {
            sophia = legacyPackages."aarch64-linux";
            gaia0 = legacyPackages."aarch64-linux";
          };
          specialArgs = {
            inherit inputs;
          };
        };
        defaults = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            sops-nix.nixosModules.sops
            impermanence.nixosModule
            attic.nixosModules.atticd
            inputs.disko.nixosModules.disko
            ./modules/tailscale-autoconnect.nix
            ./modules/tailscale-serve.nix
            ./modules/deploy-backup.nix
            ./modules/nomad-server.nix
            ./modules/nomad-client.nix
            ./modules/jellyplex-watched.nix
            ./modules/go-simple-upload-server.nix
          ];
        };

        # lxc
        plex = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/plex.nix
          ];
        };
        jellyfin = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/jellyfin.nix
          ];
        };
        arr = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/arr.nix
          ];
        };
        unifi = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/unifi.nix
          ];
        };
        atuin = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/atuin.nix
          ];
        };
        fileshare = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/fileshare.nix
          ];
        };
        vault = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/vault.nix
          ];
        };
        attic = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/attic.nix
          ];
        };
        miniflux = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/miniflux.nix
          ];
        };
        obsidian = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "lxc" ];
          imports = [
            ./lxc/template.nix
            ./lxc/obsidian.nix
          ];
        };

        # router
        sophia = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./hosts/sophia/colmena.nix
            ./hosts/sophia
          ];
        };

        # server
        chopper = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./hosts/chopper/colmena.nix
            ./hosts/chopper
          ];
        };

        # rpi cluster
        gaia0 = { name, nodes, pkgs, modulesPath, lib, ... }: {
          deployment.tags = [ "gaia" ];
          imports = [
            ./hosts/gaia
            ./hosts/gaia/gaia0.nix
          ];
        };

        # spdr
        spdr = { name, nodes, pkgs, modulesPath, lib, ... }: {
          imports = [
            ./hosts/spdr
          ];
        };
      };

      tests = {
        sophia = nixpkgs.lib.nixos.runTest {
          imports = [
            ./hosts/sophia/tests.nix
          ];
          hostPkgs = legacyPackages."x86_64-linux";
        };
      };

    };
}


