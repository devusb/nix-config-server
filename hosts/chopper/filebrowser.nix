{ config, ... }: {
  systemd.tmpfiles.settings."filebrowser-sock"."/run/filebrowser".d = {
    user = config.users.users.filebrowser.name;
    mode = "0755";
  };
  services.filebrowser = {
    enable = true;
    settings = {
      socket = "/run/filebrowser/filebrowser.sock";
      noauth = true;
    };
  };
}
