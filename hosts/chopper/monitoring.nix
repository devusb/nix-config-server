{ pkgs, config, ... }:
let
  mkConfig = { hostname, alias, exporter }: {
    targets = [
      "${hostname}:${toString config.services.prometheus.exporters."${exporter}".port}"
    ];
    labels = {
      inherit alias;
    };
  };
in
{
  services.prometheus = {
    enable = true;
    port = 9091;
    exporters = {
      zfs.enable = true;
      node.enable = true;
    };
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          (mkConfig { hostname = "localhost"; alias = "chopper"; exporter = "node"; })
          (mkConfig { hostname = "sophia"; alias = "sophia"; exporter = "node"; })
          (mkConfig { hostname = "spdr"; alias = "spdr"; exporter = "node"; })
          (mkConfig { hostname = "durandal"; alias = "durandal"; exporter = "node"; })
          (mkConfig { hostname = "gaia0"; alias = "gaia0"; exporter = "node"; })
        ];
      }
      {
        job_name = "zfs";
        scrape_interval = "1m";
        static_configs = [
          (mkConfig { hostname = "localhost"; alias = "chopper"; exporter = "zfs"; })
        ];
      }
      {
        job_name = "blocky";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "blocky-fly:4000"
            ];
            labels = {
              alias = "blocky-fly";
            };
          }
        ];
      }
    ];
  };
}
