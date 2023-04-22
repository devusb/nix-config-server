{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.31.3.6819-2ef591a4c";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "sha256-Mna6oyDGtbolUDc69ZLIpXcHNA0RzlJWgaKoey5KgR4=";
      };
    });
  };

}
