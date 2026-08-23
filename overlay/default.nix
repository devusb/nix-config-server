{ inputs, ... }:
final: prev: {
  stable = import inputs.nixpkgs-stable {
    system = prev.system;
    config.allowUnfree = true;
  };

  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.43.3.10896-cb3ebc72d";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-qgnyZt3PQI4Qz3ulYbbkVObhCbqUFjlraWW9THnzcUk=";
      };
    });
  };

  # needed until https://github.com/NixOS/nixpkgs/pull/554776 lands
  karakeep = prev.karakeep.override {
    nodejs = prev.nodejs_22;
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
