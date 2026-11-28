{ inputs, ... }:
final: prev: {
  stable = import inputs.nixpkgs-stable {
    system = prev.system;
    config.allowUnfree = true;
  };

  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

  # retries transient upload failures, https://github.com/zhaofengli/attic/pull/246
  attic-client = prev.attic-client.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch {
        url = "https://github.com/devusb/attic/commit/4a479e1.patch";
        hash = "sha256-qPpijvya8jrgldgSD2hIkxJDMwSV6GRE3gWaa51B8ZY=";
      })
    ];
  });

  plexpass = prev.plex.override {
    plexRaw = prev.plexRaw.overrideAttrs (old: rec {
      version = "1.43.5.11079-b3b13e506";
      src = prev.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        hash = "sha256-dOmnHJfgbW6SXMQ5gnkUH9g47p30RvkOdpYU+iyHogY=";
      };
    });
  };

  python314Packages = prev.python314Packages.overrideScope (
    final: prev: {
      python-ldap = prev.python-ldap.overridePythonAttrs { doCheck = false; };
    }
  );

  # 0.31 migrations require postgresql 16+
  memos = prev.memos.overrideAttrs (
    finalAttrs: old: {
      version = "0.30.0";
      src = prev.fetchFromGitHub {
        owner = "usememos";
        repo = "memos";
        rev = "v${finalAttrs.version}";
        hash = "sha256-MXvEMJN/XyZux/qL/9qZYkbo6fQzYFeCWHxFCtN1M8o=";
      };
      memos-web = old.memos-web.overrideAttrs (webOld: {
        pnpmDeps = prev.fetchPnpmDeps {
          inherit (webOld) pname version src;
          pnpm = prev.pnpm_10;
          sourceRoot = "${webOld.src.name}/web";
          fetcherVersion = 3;
          hash = "sha256-4oUA0z6VXL0belhK23wZgwCpGmLqDnEez3nMA/uHUTw=";
        };
        nativeBuildInputs = [
          prev.nodejs
          prev.pnpmConfigHook
          prev.pnpm_10
        ];
      });
      vendorHash = "sha256-nyUBXPC8nt+7s2jFHohF0PWBGky24ZSXWtSI4XVf2kU=";
      preBuild = ''
        rm -rf server/router/frontend/dist
        cp -r ${finalAttrs.memos-web} server/router/frontend/dist
      '';
    }
  );

  stump = prev.stump.overrideAttrs (
    finalAttrs: old: {
      version = "0.1.14";
      src = prev.fetchFromGitHub {
        owner = "stumpapp";
        repo = "stump";
        tag = "v${finalAttrs.version}";
        hash = "sha256-EkQId7cnqG0LGntwy8rEbrkPfqduGbD9VqlhGWsLuwk=";
      };
      frontend = old.frontend.overrideAttrs {
        yarnOfflineCache = prev.fetchYarnDeps {
          yarnLock = finalAttrs.src + "/yarn.lock";
          hash = "sha256-a48gfef+LHb/KW1cV8qTKjMwva3v18Oz7fiRhzoq+QI=";
        };
      };
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = "sha256-Ht7dueO7J7TAnMZnK0P36oDBlJYiTpKfJixq4ptCXJw=";
      };
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
