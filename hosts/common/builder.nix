{ lib, pkgs, ... }:
let
  inherit (lib) mkMerge mkIf mkDefault;
  inherit (pkgs.stdenv) isLinux isDarwin;
in
{
  users.users.nix = mkMerge [
    (mkIf isLinux {
      home = "/home/nix";
      isNormalUser = true;
    })
    (mkIf isDarwin {
      home = "/Users/nix";
      createHome = true;
      uid = 551;
      shell = "/bin/zsh";
    })
  ];

  nix.settings.trusted-users = [ "nix" ];
  nix.settings.cores = mkDefault 4;
  nix.settings.max-jobs = mkDefault 4;
}
