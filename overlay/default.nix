{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };
  nix-packages = inputs.nix-packages.packages."${prev.system}";

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

  # https://github.com/jellyfin/jellyfin/pull/10275
  jellyfin = prev.jellyfin.overrideAttrs (old: {
    patches = old.patches ++ [
      (prev.fetchpatch {
        url = "https://pkgs.rpmfusion.org/cgit/free/jellyfin.git/plain/jellyfin-vaapi-sei.patch";
        hash = "sha256-dk8Haf1jHTI+XWZXFBUu/GGvPPTNyiwBygetRuzYj34=";
      })
    ];
  });

  nzbget = prev.nzbget.overrideAttrs (old: {
    patches = [
      (prev.fetchpatch {
        url = "https://github.com/nzbget-ng/nzbget/commit/8fbbbfb40003c6f32379a562ce1d12515e61e93e.patch";
        hash = "sha256-mgI/twEoMTFMFGfH1/Jm6mE9u9/CE6RwELCSGx5erUo=";
      })
    ];
  });

}
