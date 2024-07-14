{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; config.allowUnfree = true; };

  makeModulesClosure = x:
    prev.makeModulesClosure (x // { allowMissing = true; });

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  shairport-sync = prev.shairport-sync.override {
    enableAirplay2 = true;
  };

  mongodb-5_0 = prev.callPackage ./mongodb/5.0.nix {
    sasl = prev.cyrus_sasl;
    boost = prev.boost179.override { enableShared = false; };
    python3 = prev.python311;
    inherit (prev.darwin) cctools;
    inherit (prev.darwin.apple_sdk.frameworks) CoreFoundation Security;
  };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.40.3.8555-fef15d30c";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-mJZHvK2dEaeDmmDwimBn606Ur89yPs/pitzuTFVPS1Q=";
      };
    });
  };

}
