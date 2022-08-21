{ buildGoModule
, fetchFromGitHub
, lib
, envoy
, zip
, nixosTests
, pomerium-cli
, mkYarnPackage
, fetchYarnDeps
}:

let
  inherit (lib) concatStringsSep concatMap id mapAttrsToList;
in
buildGoModule rec {
  pname = "pomerium";
  version = "0.18.0";
  src = fetchFromGitHub {
    owner = "pomerium";
    repo = "pomerium";
    rev = "v${version}";
    sha256 = "sM4kM8CqbZjl+RIsezWYVCmjoDKfGl+EQcdEaPKvVHs=";
  };

  vendorSha256 = "sha256-1EWcjfrO3FEypUUKwNwDisogERCuKOvtC7z0mC2JZn4=";

  ui = mkYarnPackage {
    inherit version;
    pname = "pomerium-ui";
    src = "${src}/ui";

    offlineCache = fetchYarnDeps {
      yarnLock = "${src}/ui/yarn.lock";
      sha256 = "sha256-Uh0y2Zmy6bSoyL5WMTce01hoH7EvSIniHyIBMxfMvhg=";
    };

    buildPhase = ''
      yarn build
    '';
  };

  subPackages = [
    "cmd/pomerium"
  ];

  patches = ./envoy_patch.diff;

  ldflags =
    let
      # Set a variety of useful meta variables for stamping the build with.
      setVars = {
        "github.com/pomerium/pomerium/internal/version" = {
          Version = "v${version}";
          BuildMeta = "nixpkgs";
          ProjectName = "pomerium";
          ProjectURL = "github.com/pomerium/pomerium";
        };
        "github.com/pomerium/pomerium/pkg/envoy" = {
          OverrideEnvoyPath = "${envoy}/bin/envoy";
        };
      };
      concatStringsSpace = list: concatStringsSep " " list;
      mapAttrsToFlatList = fn: list: concatMap id (mapAttrsToList fn list);
      varFlags = concatStringsSpace (
        mapAttrsToFlatList
          (package: packageVars:
            mapAttrsToList
              (variable: value:
                "-X ${package}.${variable}=${value}"
              )
              packageVars
          )
          setVars);
    in
    [
      "${varFlags}"
    ];

  preBuild = ''
    # Replace embedded envoy with nothing.
    # We set OverrideEnvoyPath above, so rawBinary should never get looked at
    # but we still need to set a checksum/version.
    rm pkg/envoy/files/files_{darwin,linux}*.go
    cat <<EOF >pkg/envoy/files/files_external.go
    package files

    import _ "embed" // embed

    var rawBinary []byte

    //go:embed envoy.sha256
    var rawChecksum string

    //go:embed envoy.version
    var rawVersion string
    EOF
    sha256sum '${envoy}/bin/envoy' > pkg/envoy/files/envoy.sha256
    echo '${envoy.version}' > pkg/envoy/files/envoy.version

    cp ${ui}/libexec/pomerium/deps/pomerium/dist/* ui/dist
  '';

  installPhase = ''
    install -Dm0755 $GOPATH/bin/pomerium $out/bin/pomerium
  '';

  passthru.tests = {
    inherit (nixosTests) pomerium;
    inherit pomerium-cli;
  };

  meta = with lib; {
    homepage = "https://pomerium.io";
    description = "Authenticating reverse proxy";
    license = licenses.asl20;
    maintainers = with maintainers; [ lukegb ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
