{ lib, ... }: {
  users.users.nix = {
    isNormalUser = true;
    home = "/home/nix";
  };

  nix.settings.trusted-users = [ "nix" ];
  nix.settings.cores = lib.mkDefault 4;
  nix.settings.max-jobs = lib.mkDefault 4;
}
