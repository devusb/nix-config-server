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
      version = "1.40.1.8227-c0dd5a73e";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-odCJF7gdQ2E1JE8Q+HdzyvbMNJ67k3mgu9IKz7crXQ8=";
      };
    });
  };

}
