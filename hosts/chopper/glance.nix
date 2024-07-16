{ ... }: {
  services.glance = {
    enable = true;
    settings = {
      server.port = 5678;
      pages = [{
        name = "Home";
        columns = [
          {
            size = "small";
            widgets = [
              { type = "clock"; hour-format = "12h"; timezones = [{ timezone = "Israel"; }]; }
              { type = "calendar"; }
              { type = "weather"; location = "Mont Belvieu"; units = "imperial"; }
              { type = "markets"; markets = [{ symbol = "VASGX"; } { symbol = "VSCGX"; } { symbol = "VTSAX"; }]; }
            ];
          }
          {
            size = "full";
            widgets = [
              { type = "hacker-news"; }
              { type = "lobsters"; }
              { type = "reddit"; subreddit = "houston"; }
            ];
          }
        ];
      }];
    };
  };
}
