{
  port = 53;
  httpPort = 4000;
  upstream = {
    default = [ "1.1.1.1" ];
  };
  bootstrapDns = {
    upstream = "1.1.1.1";
  };
  conditional = { };
  blocking = {
    blackLists = {
      ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
      smart_home = [
        ''
          n-devs.tplinkcloud.com
          n-deventry.tplinkcloud.com
        ''
      ];
    };
    clientGroupsBlock = {
      default = [ "ads" "smart_home" ];
    };
  };
  customDNS = {
    customTTL = "1h";
    mapping = {
      "hass.local" = "192.168.10.119";
      "gaia.local" = "192.168.20.13";
      "r2d2.local" = "192.168.99.101";
      "unifi.local" = "192.168.20.105";
      "blocky.local" = "192.168.20.120";
      "plex.local" = "192.168.20.130";
      "media.local" = "192.168.20.130";
    };
  };
}
