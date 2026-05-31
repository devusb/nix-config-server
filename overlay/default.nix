{ inputs, ... }:
final: prev: {
  stable = import inputs.nixpkgs-stable {
    system = prev.system;
    config.allowUnfree = true;
  };

  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

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

  glance = prev.glance.overrideAttrs (old: rec {
    version = "0.8.5";
    src = old.src.override {
      tag = "v${version}";
      hash = "sha256-2WFX1Gca7ign9i1zOQ9lRdtOSGq9QG33vIA5QTnq9E8=";
    };
    vendorHash = "sha256-a92V/duqvrWEb8QSJLA5rHYYZCcJ4fBC962SEr4FJDA=";
  });

  # https://github.com/NixOS/nixpkgs/issues/520485
  systemd-patched = prev.systemd.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (prev.fetchpatch {
        url = "https://github.com/systemd/systemd/commit/df45055942330fcd2b77389e449905e7f6ca34ec.patch";
        hash = "sha256-PDh4mP9rYGCglp25346nExU2v6P0WYPfLZgu+YwzZ9c=";
      })
    ];
  });

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
