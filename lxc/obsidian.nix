{ lib, pkgs, config, modulesPath, ... }:
let
  configFile = "/var/lib/couchdb/local.ini";
  initScript = pkgs.writeShellScriptBin "couchdb-init.sh" ''
    mkdir -p /var/lib/couchdb
    touch ${configFile}
    grep -q "admin" ${configFile} || cat ${config.sops.secrets.couchdb_admin.path} >> ${configFile}
    chown -R couchdb:couchdb /var/lib/couchdb
  '';
in
{
  system.stateVersion = "23.05";

  deployment = {
    targetHost = "192.168.20.104";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "obsidian";

  services.tailscale-serve = {
    enable = true;
    port = 5984;
    funnel = true;
  };

  users.users.couchdb = {
    description = "CouchDB Server user";
    group = "couchdb";
    uid = config.ids.uids.couchdb;
  };
  users.groups.couchdb.gid = config.ids.gids.couchdb;

  sops.secrets.couchdb_admin = {
    sopsFile = ../secrets/obsidian.yaml;
  };
  systemd.services.couchdb-init = {
    wantedBy = [ "couchdb.service" ];
    before = [ "couchdb.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe initScript}";
    };
  };
  services.couchdb = {
    inherit configFile;
    enable = true;
    user = "couchdb";
    group = "couchdb";
    extraConfig = ''
      [couchdb]
      single_node=true
      max_document_size = 50000000

      [chttpd]
      require_valid_user = true
      max_http_request_size = 4294967296
      enable_cors = true

      [chttpd_auth]
      require_valid_user = true
      authentication_redirect = /_utils/session.html

      [httpd]
      WWW-Authenticate = Basic realm="couchdb"
      bind_address = 0.0.0.0
      enable_cors = true

      [cors]
      origins = app://obsidian.md,capacitor://localhost,http://localhost
      credentials = true
      headers = accept, authorization, content-type, origin, referer
      methods = GET,PUT,POST,HEAD,DELETE
      max_age = 3600
    '';
  };

}
