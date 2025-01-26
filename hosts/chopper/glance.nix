{
  config,
  lib,
  caddyHelpers,
  ...
}:
{
  services.glance = {
    enable = true;
    settings = {
      server.port = 5678;
      pages = [
        {
          name = "Home";
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "bookmarks";
                  groups = lib.lists.singleton {
                    links = [
                      {
                        title = "Gmail";
                        url = "https://gmail.com";
                      }
                      {
                        title = "Miniflux";
                        url = "https://rss.devusb.us";
                      }
                      {
                        title = "Home Assistant";
                        url = "https://hass.devusb.us";
                      }
                      {
                        title = "Hoarder";
                        url = "https://hoarder.chopper.devusb.us";
                      }
                      {
                        title = "GitHub";
                        url = "https://github.com";
                      }
                      {
                        title = "NixOS Status";
                        url = "https://status.nixos.org";
                      }
                    ];
                  };
                }
                {
                  type = "clock";
                  hour-format = "12h";
                  timezones = [ { timezone = "Israel"; } ];
                }
                { type = "calendar"; }
                {
                  type = "weather";
                  location = "Mont Belvieu";
                  units = "imperial";
                }
                {
                  type = "markets";
                  markets = [
                    { symbol = "VASGX"; }
                    { symbol = "VSCGX"; }
                    { symbol = "VTSAX"; }
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "group";
                  widgets = [
                    { type = "hacker-news"; }
                    { type = "lobsters"; }

                  ];
                }
                {
                  type = "group";
                  widgets =
                    let
                      subreddits = [
                        "houston"
                        "gamedeals"
                        "buildapcsales"
                        "nixos"
                        "selfhosted"
                        "steamdeck"
                        "ockytop"
                      ];
                      mkRedditWidget = subreddit: {
                        inherit subreddit;
                        type = "reddit";
                      };
                    in
                    map mkRedditWidget subreddits;
                }
              ];
            }
          ];
        }
      ];
    };
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "glance.${domain}" = helpers.mkVirtualHost config.services.glance.settings.server.port;
  };

}
