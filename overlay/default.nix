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

  # https://github.com/NixOS/nixpkgs/pull/274063
  zigbee2mqtt = prev.zigbee2mqtt.override {
    buildNpmPackage = prev.buildNpmPackage.override {
      nodejs = prev.nodejs_18;
    };
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

  unifi7 =
    let
      version = "7.5.187";
      suffix = "-f57f5bf7ab";
      sha256 = "sha256-a5kl8gZbRnhS/p1imPl7soM0/QSFHdM0+2bNmDfc1mY=";
    in
    prev.unifi7.overrideAttrs (old: {
      src = prev.fetchurl {
        url = "https://dl.ubnt.com/unifi/${version}${suffix}/unifi_sysvinit_all.deb";
        inherit sha256;
      };
    });

}
