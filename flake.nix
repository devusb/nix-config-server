{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, ... }: {
    packages.x86_64-linux = {
      proxmox = nixos-generators.nixosGenerate {
        modules = [
        	./template.nix
        ];
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        format = "proxmox-lxc";
      };
    };
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      # Also see the non-Flakes hive.nix example above.
      plex = { name, nodes, pkgs, modulesPath, lib, ... }: {
        imports = [
          ./lxc/plex.nix
        ];
        deployment = {
          targetHost = "192.168.20.10";
          targetPort = 22;
          targetUser = "root";
          replaceUnknownProfiles = true;
        };
      };
    };
  };
}


