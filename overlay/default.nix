{ inputs, ... }: final: prev: {
  stable = import inputs.nixpkgs-stable { system = prev.system; };

  deployBackup = { backup_name, backup_files_list, backup_url ? "http://192.168.20.133:25478/upload?token=59af2e561fc9f80a9bb9" }:
    prev.writeShellScriptBin "deployBackup" ''
      tar cvzf /tmp/${backup_name}.tar.gz ${prev.lib.strings.concatMapStrings (x: " " + x) backup_files_list}
      curl -Ffile=@/tmp/${backup_name}.tar.gz '${backup_url}'
      rm /tmp/${backup_name}.tar.gz
      logger "${backup_name} backup completed $(date)"
    '';

  blockyConfig = import ./blocky-config.nix;

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

}
