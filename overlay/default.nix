{ inputs, ... }:
final: prev: {
  stable = import inputs.nixpkgs-stable {
    system = prev.system;
    config.allowUnfree = true;
  };

  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

  stump = prev.stump.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch {
        # koreader progress pull returning 500
        url = "https://github.com/devusb/stump/commit/6413ef2dc2e77cdf2840e79133b8f7269cf6069f.patch";
        hash = "sha256-qKRF0XXK7MFA/47SmNdcuvKvlCFErL8cJUzR9mm3R28=";
      })
      (prev.fetchpatch {
        # fix oidc migration
        url = "https://github.com/stumpapp/stump/commit/e95b9218149f3597e809d8581d12088571f5e366.patch";
        hash = "sha256-zHHdzAkVxwoPBDKONrr+1XHTlqU+B4713WkRIvJTBIA=";
      })
    ];
    doCheck = false;
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

  python314Packages = prev.python314Packages.overrideScope (
    final: prev: {
      python-ldap = prev.python-ldap.overridePythonAttrs { doCheck = false; };
    }
  );

  fish = prev.fish.overrideAttrs {
    doCheck = false;
  };

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (self: super: {
      flask-limiter = super.flask-limiter.overridePythonAttrs (old: {
        pythonRelaxDeps = [ "rich" ];
      });
    })
  ];

}
