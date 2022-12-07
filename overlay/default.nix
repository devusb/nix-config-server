{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  tailscale-unstable =
    let
      version = "1.34.0";
      src = prev.fetchFromGitHub {
        owner = "tailscale";
        repo = "tailscale";
        rev = "v${version}";
        sha256 = "sha256-ngcFoEDec/6I9gWpJ767ju2OvZfS4RhlSbK//xXIFxs=";
      };
    in
    (prev.tailscale.override {
      buildGoModule = args: prev.buildGoModule.override { } (args // {
        inherit src version;
        vendorSha256 = "sha256-nSllDi6G4QAGyuoGduDhI0vaVuN2//eg+gXRSZ3ERiQ=";
        ldflags = [ "-X tailscale.com/version.Long=${version}" "-X tailscale.com/version.Short=${version}" ];
      });
    });

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

}
