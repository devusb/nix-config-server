{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-packages = {
      url = "github:devusb/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    buildbot-nix = {
      url = "github:nix-community/buildbot-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pingshutdown = {
      url = "github:devusb/pingshutdown";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-3.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      darwin,
      nix-packages,
      nixos-generators,
      flake-parts,
      sops-nix,
      impermanence,
      blocky-tailscale,
      disko,
      colmena,
      buildbot-nix,
      pingshutdown,
      lix-module,
      treefmt-nix,
      ...
    }@inputs:
    let
      overlays = {
        default = import ./overlay { inherit inputs; };
      };
      defaultImports = [
        sops-nix.nixosModules.sops
        impermanence.nixosModule
        disko.nixosModules.disko
        pingshutdown.nixosModules.pingshutdown
        nix-packages.nixosModules.default
        buildbot-nix.nixosModules.buildbot-master
        buildbot-nix.nixosModules.buildbot-worker
        ./modules/tailscale-autoconnect.nix
        ./modules/tailscale-serve.nix
        ./modules/deploy-backup.nix
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {
        imports = [
          treefmt-nix.flakeModule
        ];
        perSystem =
          {
            system,
            lib,
            pkgs,
            ...
          }:
          rec {
            legacyPackages = import nixpkgs {
              inherit system;
              overlays = builtins.attrValues overlays;
              config = {
                allowUnfree = true;
                nvidia.acceptLicense = true;
                permittedInsecurePackages = [
                  # https://github.com/NixOS/nixpkgs/issues/360592
                  "aspnetcore-runtime-6.0.36"
                  "aspnetcore-runtime-wrapped-6.0.36"
                  "dotnet-sdk-6.0.428"
                  "dotnet-sdk-wrapped-6.0.428"
                ];
              };
            };
            _module.args.pkgs = legacyPackages;

            treefmt = {
              programs.nixfmt.enable = true;
              programs.nixfmt.package = pkgs.nixfmt-rfc-style;
              programs.yamlfmt.enable = true;
              programs.mdformat.enable = true;
              programs.toml-sort.enable = true;
              programs.black.enable = true;
              programs.shfmt.enable = true;
              settings.excludes = [
                ".editorconfig"
                ".gitignore"
                "flake.lock"
                "*secrets*"
              ];
            };

            checks =
              let
                nixosMachinesPerSystem = {
                  x86_64-linux = [
                    "chopper"
                    "spdr"
                  ];
                  aarch64-linux = [
                    "the-doctor"
                    "gaia0"
                    "gaia1"
                    "sophia"
                  ];
                };
                darwinMachinesPerSystem = {
                  aarch64-darwin = [
                    "cortana"
                  ];
                };
                nixosMachines = lib.mapAttrs' (n: lib.nameValuePair "nixos-${n}") (
                  lib.genAttrs (nixosMachinesPerSystem.${system} or [ ]) (
                    name: self.nixosConfigurations.${name}.config.system.build.toplevel
                  )
                );
                darwinMachines = lib.mapAttrs' (n: lib.nameValuePair "darwin-${n}") (
                  lib.genAttrs (darwinMachinesPerSystem.${system} or [ ]) (
                    name: self.darwinConfigurations.${name}.config.system.build.toplevel
                  )
                );
              in
              nixosMachines // darwinMachines;
          };

        flake = {
          images = {
            sophia = withSystem "aarch64-linux" (
              { pkgs, ... }:
              nixos-generators.nixosGenerate {
                inherit pkgs;
                modules = defaultImports ++ [
                  ./hosts/sophia
                ];
                format = "sd-aarch64-installer";
              }
            );
            blocky-fly = withSystem "x86_64-linux" (
              { pkgs, system, ... }:
              blocky-tailscale.packages.${system}.blocky-tailscale.override {
                blockyConfig = pkgs.writeText "blocky.conf" (
                  builtins.toJSON (import ./images/blocky-fly/blocky-config.nix { })
                );
              }
            );
            gaia = withSystem "aarch64-linux" (
              { pkgs, ... }:
              nixos-generators.nixosGenerate {
                inherit pkgs;
                modules = defaultImports ++ [
                  ./hosts/gaia
                ];
                specialArgs = {
                  inherit inputs;
                };
                format = "sd-aarch64-installer";
              }
            );
            pomerium = withSystem "x86_64-linux" (
              { pkgs, ... }: pkgs.dockerTools.buildLayeredImage (import ./images/pomerium pkgs)
            );
          };

          nixosConfigurations = {
            sophia = withSystem "aarch64-linux" (
              { pkgs, system, ... }:
              nixpkgs.lib.nixosSystem {
                inherit pkgs;
                extraModules = [ colmena.nixosModules.deploymentOptions ];
                modules = defaultImports ++ [
                  { nixpkgs.system = system; } # needed to use aarch64-linux packages
                  ./hosts/sophia
                  ./hosts/sophia/colmena.nix
                ];
              }
            );

            chopper = withSystem "x86_64-linux" (
              { pkgs, ... }:
              nixpkgs.lib.nixosSystem {
                inherit pkgs;
                specialArgs = {
                  inherit inputs;
                };
                extraModules = [ colmena.nixosModules.deploymentOptions ];
                modules = defaultImports ++ [
                  ./hosts/chopper
                  ./hosts/chopper/colmena.nix
                ];
              }
            );

            gaia0 = withSystem "aarch64-linux" (
              { pkgs, system, ... }:
              nixpkgs.lib.nixosSystem {
                inherit pkgs;
                specialArgs = {
                  inherit inputs;
                };
                extraModules = [ colmena.nixosModules.deploymentOptions ];
                modules = defaultImports ++ [
                  { nixpkgs.system = system; }
                  ./hosts/gaia
                  ./hosts/gaia/gaia0.nix
                ];
              }
            );

            gaia1 = withSystem "aarch64-linux" (
              { pkgs, system, ... }:
              nixpkgs.lib.nixosSystem {
                inherit pkgs;
                specialArgs = {
                  inherit inputs;
                };
                extraModules = [ colmena.nixosModules.deploymentOptions ];
                modules = defaultImports ++ [
                  { nixpkgs.system = system; }
                  ./hosts/gaia
                  ./hosts/gaia/gaia1.nix
                ];
              }
            );

            spdr = withSystem "x86_64-linux" (
              { pkgs, ... }:
              nixpkgs.lib.nixosSystem {
                inherit pkgs;
                extraModules = [ colmena.nixosModules.deploymentOptions ];
                modules = defaultImports ++ [
                  ./hosts/spdr
                ];
              }
            );

            the-doctor = withSystem "aarch64-linux" (
              { pkgs, ... }:
              nixpkgs.lib.nixosSystem {
                inherit pkgs;
                specialArgs = {
                  inherit inputs;
                };
                extraModules = [ colmena.nixosModules.deploymentOptions ];
                modules = defaultImports ++ [
                  ./hosts/the-doctor
                ];
              }
            );
          };

          darwinConfigurations = {
            cortana = withSystem "aarch64-darwin" (
              { pkgs, ... }:
              darwin.lib.darwinSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  sops-nix.darwinModules.sops
                  nix-packages.darwinModules.default
                  lix-module.nixosModules.default
                  { nixpkgs.pkgs = pkgs; }
                  ./hosts/cortana
                ];
              }
            );
          };

          colmena =
            let
              conf = self.nixosConfigurations;
            in
            withSystem "x86_64-linux" (
              { pkgs, ... }:
              {
                meta = {
                  nixpkgs = pkgs;
                  nodeSpecialArgs = builtins.mapAttrs (name: value: value._module.specialArgs) conf;
                };
              }
            )
            // builtins.mapAttrs (name: value: { imports = value._module.args.modules; }) conf;

          checks."x86_64-linux" = {
            sophia = withSystem "x86_64-linux" (
              { pkgs, ... }:
              nixpkgs.lib.nixos.runTest {
                imports = [
                  ./hosts/sophia/tests.nix
                ];
                hostPkgs = pkgs;
                node.specialArgs = {
                  inherit inputs;
                };
              }
            );
          };
        };

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

      }
    );

}
