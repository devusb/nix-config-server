{ ... }:
{
  services.nfs.server = {
    enable = true;
    exports = ''
      /r2d2_0/media 192.168.0.0/16(rw,async,no_subtree_check,no_root_squash,insecure)
      /r2d2_0/media/Roms 100.64.0.0/10(rw,async,no_subtree_check,no_root_squash,insecure)
      /r2d2_0/backup 192.168.0.0/16(rw,async,no_subtree_check,no_root_squash,insecure)
      /r2d2_0/homes 192.168.0.0/16(rw,async,subtree_check,no_root_squash,crossmnt)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];

  services.samba = {
    enable = true;
    settings = {
      homes = {
        "browsable" = "no";
        "map archive" = "yes";
        "read only" = "no";
      };
      media = {
        path = "/r2d2_0/media";
        browsable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0777";
        "directory mask" = "0777";
      };
    };
  };

}
