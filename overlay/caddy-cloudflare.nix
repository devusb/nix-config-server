{ srcOnly, fetchFromGitHub, go, buildGoModule, stdenv, lib, installShellFiles, ... }:
let
  version = "2.6.2";
  caddySrc = srcOnly (fetchFromGitHub {
    owner = "caddyserver";
    repo = "caddy";
    rev = "v${version}";
    sha256 = "sha256-Tbf6RB3106OEZGc/Wx7vk+I82Z8/Q3WqnID4f8uZ6z0=";
  });
  dist = fetchFromGitHub {
    owner = "caddyserver";
    repo = "dist";
    rev = "v${version}";
    sha256 = "sha256-EXs+LNb87RWkmSWvs8nZIVqRJMutn+ntR241gqI7CUg=";
  };

  pluginSrc = srcOnly (fetchFromGitHub {
    owner = "caddy-dns";
    repo = "cloudflare";
    rev = "815abbf88b27182428c342b2916a37b7134d266b";
    sha256 = "sha256-tz12CLrXLCf8Tjb9yj9rnysS3seLg3GAVFpybu3rIo8=";
  });

  combinedSrc = stdenv.mkDerivation {
    name = "caddy-src";

    nativeBuildInputs = [ go ];

    buildCommand = ''
      export GOCACHE="$TMPDIR/go-cache"
      export GOPATH="$TMPDIR/go"

      mkdir -p "$out/ourcaddy"

      cp -r ${caddySrc} "$out/caddy"
      cp -r ${pluginSrc} "$out/plugin"

      cd "$out/ourcaddy"

      go mod init caddy
      echo "package main" >> main.go
      echo 'import caddycmd "github.com/caddyserver/caddy/v2/cmd"' >> main.go
      echo 'import _ "github.com/caddyserver/caddy/v2/modules/standard"' >> main.go
      echo 'import _ "github.com/caddy-dns/cloudflare"' >> main.go
      echo "func main(){ caddycmd.Main() }" >> main.go
      go mod edit -require=github.com/caddyserver/caddy/v2@v2.0.0
      go mod edit -replace github.com/caddyserver/caddy/v2=../caddy
      go mod edit -require=github.com/caddy/v2/modules/standard@v1
      go mod edit -replace github.com/caddy/v2/modules/standard=../caddy
      go mod edit -require=github.com/caddy-dns/cloudflare@v0.0.0
      go mod edit -replace github.com/caddy-dns/cloudflare=../plugin
    '';
  };
in
buildGoModule {
  name = "caddy-cloudflare";
  src = combinedSrc;

  vendorSha256 = "sha256-af0Qse06X93WCdtPPhs/KDbx8mn9XgWYy9DcesZfHEg=";

  overrideModAttrs = _: {
    postPatch = "cd ourcaddy";

    postConfigure = ''
      go mod tidy
    '';

    postInstall = ''
      mkdir -p "$out/.magic"
      cp go.mod go.sum "$out/.magic"
    '';
  };

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];

  doCheck = false;

  postPatch = "cd ourcaddy";

  postConfigure = ''
    cp vendor/.magic/go.* .
  '';

  postInstall = ''
    install -Dm644 ${dist}/init/caddy-api.service -t $out/lib/systemd/system
    substituteInPlace $out/lib/systemd/system/caddy-api.service --replace "/usr/bin/caddy" "$out/bin/caddy"
  '';

}
