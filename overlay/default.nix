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

  fish = prev.fish.overrideAttrs {
    doCheck = false;
  };

  memos = prev.memos.overrideAttrs (old: rec {
    version = "0.25.3";
    src = old.src.override {
      rev = "v${version}";
      hash = "sha256-lAKzPteGjGa7fnbB0Pm3oWId5DJekbVWI9dnPEGbiBo=";
    };

    vendorHash = "sha256-BoJxFpfKS/LByvK4AlTNc4gA/aNIvgLzoFOgyal+aF8";

    preBuild =
      let
        memos-web = old.memos-web.overrideAttrs {
          inherit src;
          pnpmDeps = prev.pnpm.fetchDeps {
            inherit (old) pname;
            inherit version src;
            sourceRoot = "${src.name}/web";
            fetcherVersion = 1;
            hash = "sha256-k+pykzAiZ72cMMH+6qtnNxjaq4m4QyCQuWvQPbZSZho";
          };
        };
      in
      ''
        rm -rf server/router/frontend/dist
        cp -r ${memos-web} server/router/frontend/dist
      '';
  });

  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (self: super: {
      flask-limiter = super.flask-limiter.overridePythonAttrs (old: {
        pythonRelaxDeps = [ "rich" ];
      });
    })
  ];

}
