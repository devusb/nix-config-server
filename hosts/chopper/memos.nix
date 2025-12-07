{ config, caddyHelpers, ... }:
{
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "memos";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "memos" ];
  };

  services.memos = {
    enable = true;
    settings = {
      MEMOS_INSTANCE_URL = "https://memos.chopper.devusb.us";
      MEMOS_DRIVER = "postgres";
      MEMOS_DSN = "postgresql:///memos?host=/run/postgresql";
      MEMOS_MODE = "prod";
      MEMOS_ADDR = "127.0.0.1";
      MEMOS_PORT = "5230";
      MEMOS_DATA = config.services.memos.dataDir;
    };
  };
  systemd.services.memos.serviceConfig = {
    RuntimeDirectory = "memos";
    RuntimeDirectoryMode = "0777";
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "memos.${domain}" = helpers.mkVirtualHost 5230;
  };

}
