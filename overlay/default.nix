{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  tailscale-unstable =
    let
      version = "1.33.298";
      src = prev.fetchFromGitHub {
        owner = "tailscale";
        repo = "tailscale";
        rev = "300aba61a6bdd51256f2a3d9453e5e459ed4cfc6";
        sha256 = "sha256-igIUhU8Rv/1xmZmbskwfUXXjM2jp7dGjtkgcO5qPtB4=";
      };
    in
    (prev.tailscale.override {
      buildGoModule = args: prev.buildGoModule.override { } (args // {
        inherit src version;
        vendorSha256 = "sha256-fbRdC98V55KqzlkJRqTcjsqod4CUYL2jDgXxRmwvfSE=";
        ldflags = [ "-X tailscale.com/version.Long=${version}" "-X tailscale.com/version.Short=${version}" ];
      });
    });

  caddy-cloudflare = prev.callPackage ./caddy-cloudflare.nix { };

}
