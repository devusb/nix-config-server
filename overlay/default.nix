{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.32.4.7195-7c8f9d3b6";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "sha256-lnkhjzBW9DENCVJNP+4h8fVVUh4LhnJ1XjrCjF3ngKE=";
      };
    });
  };

}
