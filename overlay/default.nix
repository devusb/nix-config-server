{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };
  nix-config = inputs.nix-config.legacyPackages."${prev.system}";

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.32.8.7639-fb6452ebf";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-jdGVAdvm7kjxTP3CQ5w6dKZbfCRwSy9TrtxRHaV0/cs";
      };
    });
  };

  # https://github.com/jellyfin/jellyfin/pull/10275
  jellyfin = prev.jellyfin.overrideAttrs (old: {
    patches = old.patches ++ [
      (prev.fetchpatch {
        url = "https://pkgs.rpmfusion.org/cgit/free/jellyfin.git/plain/jellyfin-vaapi-sei.patch";
        hash = "sha256-dk8Haf1jHTI+XWZXFBUu/GGvPPTNyiwBygetRuzYj34=";
      })
    ];
  });

  tautulli = prev.tautulli.overrideAttrs (old: rec {
    version = "2.13.4";
    src = prev.fetchFromGitHub {
      owner = "Tautulli";
      repo = old.pname;
      rev = "v${version}";
      sha256 = "sha256-cOHirjYdfPPv7O9o3vnsKBffvqxoaRN32NaUOK0SmQ8=";
    };
  });

  # https://github.com/NixOS/nixpkgs/pull/281440
  mongodb-4_4 = prev.mongodb-4_4.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      prev.net-snmp
      prev.openldap
    ];
  });

}
