{ inputs, ... }:
final: prev: {
  stable = import inputs.nixpkgs-stable {
    system = prev.system;
    config.allowUnfree = true;
  };

  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

  buildbot = prev.buildbot.overrideAttrs (old: {
    patches = old.patches ++ [
      (prev.fetchpatch {
        url = "https://github.com/buildbot/buildbot/commit/ac46c0aa77be46eaa64e09bef03da6f8dbaacfa7.patch";
        hash = "sha256-XoODSKY0GzFh2H5gWxiXm/QxngGN2MM0yId5D1RQflQ=";
      })
    ];
  });

  # https://github.com/jellyfin/jellyfin/issues/13147
  jellyfin = prev.jellyfin.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch2 {
        url = "https://patch-diff.githubusercontent.com/raw/jellyfin/jellyfin/pull/13227.diff";
        hash = "sha256-gVmLWsvGk6dqSpjdnuKWmghH8hp7WbaiZC5z9VwxOv4=";
      })
    ];
  });

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.41.3.9314-a0bfb8370";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-ku16UwIAAdtMO1ju07DwuWzfDLg/BjqauWhVDl68/DI=";
      };
    });
  };

}
