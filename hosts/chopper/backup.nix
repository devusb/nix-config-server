{ pkgs, config, ... }:
{
  users.groups.backup = {
    gid = 1003;
  };
  services.go-simple-upload-server = {
    enable = true;
    package = pkgs.nix-config.go-simple-upload-server;
    settings = {
      token = "59af2e561fc9f80a9bb9";
      addr = "127.0.0.1:8081";
      max_upload_size = 1073741824;
      document_root = "/r2d2_0/backup/config";
    };
    group = config.users.groups.backup.name;
  };

}
