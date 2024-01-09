{ pkgs, config, ... }:
let
  backupPath = "/tmp/atuin_db.tar";
in
{
  imports = [
    ../../modules/tailscale-serve.nix
    ../../modules/deploy-backup.nix
  ];
  networking.hostName = "atuin";

  services.tailscale-serve = {
    enable = true;
    port = 8888;
    funnel = true;
    authKeyFile = "/run/secrets/ts_key";
  };

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    openRegistration = false;
  };

  services.deploy-backup = {
    enable = true;
    backups.atuin = {
      files = [
        backupPath
      ];
      backupScript = with pkgs; ''
        ${config.security.wrapperDir}/sudo -u postgres ${postgresql}/bin/pg_dump -d atuin -F t -f ${backupPath}
      '';
    };
  };

  system.stateVersion = "24.05";

}
