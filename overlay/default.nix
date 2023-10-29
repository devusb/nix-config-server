{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.32.7.7621-871adbd44";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-ThKN1ZiuSt7+8O2xCCGDQm7CB2iv/uvzhKaxC4AnUWQ=";
      };
    });
  };

  # spidermonkey seems incompatible with python311 due to deprecated file mode
  spidermonkey_91 = prev.spidermonkey_91.override {
    python3 = prev.python310;
  };

}
