{ upstreamDns ? [ "127.0.0.1:5353" ], bootstrapDns ? "1.1.1.1", ... }: {
  port = 53;
  httpPort = 4000;
  upstream = {
    default = upstreamDns;
  };
  bootstrapDns = {
    upstream = bootstrapDns;
  };
  prometheus = {
    enable = true;
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
}
