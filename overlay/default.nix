{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.30.1.6497-5fc2e0894";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "sha256-VwaetJED30ot62LIJi8Ix5IrIa7irbzdGFZbIqz3PgU";
      };
    });
  };
}
