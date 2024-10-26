{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; config.allowUnfree = true; };

  makeModulesClosure = x:
    prev.makeModulesClosure (x // { allowMissing = true; });

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  shairport-sync = prev.shairport-sync.override {
    enableAirplay2 = true;
  };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.41.0.8992-8463ad060";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-ldBJz2nqlzcx/FvKzMCgXkVO0omcojlU9sq6fAiknD8=";
      };
    });
  };

}
