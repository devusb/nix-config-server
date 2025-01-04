{
  upstreamDns ? [ "127.0.0.1:5353" ],
  bootstrapDns ? "1.1.1.1",
  ...
}:
{
  ports = {
    dns = 53;
    http = 4000;
  };
  upstreams.groups = {
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
    denylists = {
      ads = [ "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" ];
      smart_home = [
        ''
          n-devs.tplinkcloud.com
          n-deventry.tplinkcloud.com
        ''
      ];
    };
    allowlists = {
      ads = [
        ''
          tags.tiqcdn.com
        ''
      ];
    };
    clientGroupsBlock = {
      default = [
        "ads"
        "smart_home"
      ];
    };
  };
}
