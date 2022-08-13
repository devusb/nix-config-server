{ stdenv
, lib
, fetchurl
, openssl
, zlib
, autoPatchelfHook
}:

stdenv.mkDerivation rec {
  pname = "pomerium";
  version = "0.18.0";

  src = fetchurl {
    url = "https://github.com/pomerium/pomerium/releases/download/v${version}/pomerium-linux-amd64.tar.gz";
    sha256 = "sha256-sDTwmMM3/hVfu1jVht8RgItSPMxwyGDh6goK0TkKDEg=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    openssl
    zlib
  ];

  sourceRoot = ".";

  installPhase = ''
    install -m755 -D pomerium $out/bin/pomerium
  '';

  meta = with lib; {
    homepage = "https://pomerium.io";
    description = "Pomerium!";
  };
}
