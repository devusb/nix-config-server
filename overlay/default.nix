{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.31.0.6654-02189b09f";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "sha256-TTEcyIBFiuJTNHeJ9wu+4o2ol72oCvM9FdDPC83J3Mc=";
      };
    });
  };
}
