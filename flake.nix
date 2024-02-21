{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nix-packages = {
      url = "github:devusb/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    hercules-ci-effects.url = "github:mlabs-haskell/hercules-ci-effects/push-cache-effect";
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
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pingshutdown = {
      url = "github:devusb/pingshutdown";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-packages, nixos-generators, flake-parts, hercules-ci-effects, sops-nix, impermanence, blocky-tailscale, attic, disko, colmena, pingshutdown, ... }@inputs:
    let
      overlays = { default = import ./overlay { inherit inputs; }; };
      defaultImports = [
        sops-nix.nixosModules.sops
        impermanence.nixosModule
        attic.nixosModules.atticd
        disko.nixosModules.disko
        pingshutdown.nixosModules.pingshutdown
        nix-packages.nixosModules.default
        ./modules/tailscale-autoconnect.nix
        ./modules/tailscale-serve.nix
        ./modules/deploy-backup.nix
        ./modules/nomad-server.nix
        ./modules/nomad-client.nix
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        hercules-ci-effects.flakeModule
        hercules-ci-effects.push-cache-effect
      ];

      perSystem = { system, ... }: rec {
        legacyPackages =
          import nixpkgs {
            inherit system;
            overlays = builtins.attrValues overlays;
            config = {
              allowUnfree = true;
              nvidia.acceptLicense = true;
            };
          };

        formatter = legacyPackages.nixpkgs-fmt;
      };

      flake = with self; {
        # images
        images = {
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
            specialArgs = { inherit inputs; };
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

        nixosConfigurations = {
          sophia =
            let system = "aarch64-linux";
            in
            nixpkgs.lib.nixosSystem {
              pkgs = legacyPackages."${system}";
              extraModules = [ colmena.nixosModules.deploymentOptions ];
              modules = defaultImports ++ [
                { nixpkgs.system = system; } # needed to use aarch64-linux packages
                ./hosts/sophia
                ./hosts/sophia/colmena.nix
              ];
            };

          chopper =
            let system = "x86_64-linux";
            in
            nixpkgs.lib.nixosSystem {
              pkgs = legacyPackages."${system}";
              specialArgs = { inherit inputs; };
              extraModules = [ colmena.nixosModules.deploymentOptions ];
              modules = defaultImports ++ [
                ./hosts/chopper
                ./hosts/chopper/colmena.nix
              ];
            };

          gaia0 =
            let system = "aarch64-linux";
            in
            nixpkgs.lib.nixosSystem {
              pkgs = legacyPackages."${system}";
              specialArgs = { inherit inputs; };
              extraModules = [ colmena.nixosModules.deploymentOptions ];
              modules = defaultImports ++ [
                { nixpkgs.system = system; }
                ./hosts/gaia
                ./hosts/gaia/gaia0.nix
              ];
            };

          gaia1 =
            let system = "aarch64-linux";
            in
            nixpkgs.lib.nixosSystem {
              pkgs = legacyPackages."${system}";
              specialArgs = { inherit inputs; };
              extraModules = [ colmena.nixosModules.deploymentOptions ];
              modules = defaultImports ++ [
                { nixpkgs.system = system; }
                ./hosts/gaia
                ./hosts/gaia/gaia1.nix
              ];
            };

          spdr =
            let system = "x86_64-linux";
            in
            nixpkgs.lib.nixosSystem {
              pkgs = legacyPackages."${system}";
              extraModules = [ colmena.nixosModules.deploymentOptions ];
              modules = defaultImports ++ [
                ./hosts/spdr
              ];
            };
        };

        colmena =
          let conf = self.nixosConfigurations;
          in
          {
            meta = {
              nixpkgs = legacyPackages."x86_64-linux";
              nodeSpecialArgs = builtins.mapAttrs (name: value: value._module.specialArgs) conf;
            };
          } // builtins.mapAttrs (name: value: { imports = value._module.args.modules; }) conf;

        checks."x86_64-linux" = {
          sophia = nixpkgs.lib.nixos.runTest {
            imports = [
              ./hosts/sophia/tests.nix
            ];
            hostPkgs = legacyPackages."x86_64-linux";
            node.specialArgs = { inherit inputs; };
          };
        };
      };

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
      ];

      herculesCI = { ... }: {
        ciSystems = [ "x86_64-linux" "aarch64-linux" ];
      };

      push-cache-effect = {
        enable = true;
        attic-client-pkg = attic.packages.x86_64-linux.attic-client;
        caches.r2d2 = {
          type = "attic";
          secretName = "attic";
          packages = map (host: self.nixosConfigurations."${host}".config.system.build.toplevel) (builtins.attrNames self.nixosConfigurations);
        };
      };

    };
}


