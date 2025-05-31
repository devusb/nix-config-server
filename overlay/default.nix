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

  coturn = prev.coturn.overrideAttrs (old: rec {
    version = "4.7.0";
    src = old.src.override {
      tag = version;
      hash = "sha256-nvImelAvcbHpv6JTxX+sKpldVXG6u9Biu+VDt95r9I4=";
    };
  });

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (self: super: {
      flask-limiter = super.flask-limiter.overridePythonAttrs (old: {
        pythonRelaxDeps = [ "rich" ];
      });
    })
  ];

}
