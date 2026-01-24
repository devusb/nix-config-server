{
  lib,
  config,
  caddyHelpers,
  ...
}:
let
  mkConfig =
    {
      hostname,
      alias,
      exporter,
    }:
    {
      targets = [
        "${hostname}:${toString config.services.prometheus.exporters."${exporter}".port}"
      ];
      labels = {
        inherit alias;
      };
    };
in
{
  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "grafana" ];
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        protocol = "socket";
        socket = "/run/grafana/grafana.sock";
        socket_mode = "0666";
        root_url = "https://grafana.chopper.devusb.us";
      };
      database = {
        type = "postgres";
        user = "grafana";
        host = "/run/postgresql";
      };
      users = {
        allow_sign_up = false;
        auto_assign_org = true;
        auto_assign_org_role = "Admin";
      };
      auth = {
        signout_redirect_url = "https://auth.devusb.us/application/o/grafana/end-session/";
        oauth_auto_login = true;
      };
      "auth.generic_oauth" = {
        name = "authentik";
        enabled = true;
        scopes = "openid email profile";
        auth_url = "https://auth.devusb.us/application/o/authorize/";
        token_url = "https://auth.devusb.us/application/o/token/";
        api_url = "https://auth.devusb.us/application/o/userinfo/";
      };
      panels = {
        disable_sanitize_html = true;
      };
    };
    provision = {
      datasources.settings.datasources = [
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
          access = "proxy";
        }
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9091";
          access = "proxy";
        }
      ];
      alerting.contactPoints.settings.contactPoints = [
        {
          name = "pushover";
          receivers = lib.singleton {
            uid = "pushover";
            type = "pushover";
            disableResolveMessage = false;
            settings = {
              apiToken = "$PINGSHUTDOWN_NOTIFICATIONTOKEN";
              userKey = "$PINGSHUTDOWN_NOTIFICATIONUSER";
            };
          };
        }
      ];
      alerting.policies.settings.policies = [
        {
          orgid = 1;
          receiver = "pushover";
          group_by = [
            "grafana_folder"
            "alertname"
          ];
        }
      ];
    };
  };
  systemd.services.grafana.serviceConfig.EnvironmentFile = config.sops.secrets.grafana.path;

  services.prometheus = {
    enable = true;
    port = 9091;
    exporters = {
      zfs.enable = true;
      smartctl = {
        enable = true;
        devices = [
          "/dev/sda"
          "/dev/sdb"
          "/dev/sdc"
          "/dev/sdd"
        ];
      };
    };
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          (mkConfig {
            hostname = "localhost";
            alias = "chopper";
            exporter = "node";
          })
          (mkConfig {
            hostname = "sophia";
            alias = "sophia";
            exporter = "node";
          })
          (mkConfig {
            hostname = "spdr";
            alias = "spdr";
            exporter = "node";
          })
          (mkConfig {
            hostname = "durandal";
            alias = "durandal";
            exporter = "node";
          })
          (mkConfig {
            hostname = "gaia0";
            alias = "gaia0";
            exporter = "node";
          })
          (mkConfig {
            hostname = "gaia1";
            alias = "gaia1";
            exporter = "node";
          })
          (mkConfig {
            hostname = "the-doctor";
            alias = "the-doctor";
            exporter = "node";
          })
          (mkConfig {
            hostname = "cortana";
            alias = "cortana";
            exporter = "node";
          })
          (mkConfig {
            hostname = "superintendent";
            alias = "superintendent";
            exporter = "node";
          })
        ];
      }
      {
        job_name = "zfs";
        scrape_interval = "1m";
        static_configs = [
          (mkConfig {
            hostname = "localhost";
            alias = "chopper";
            exporter = "zfs";
          })
        ];
      }
      {
        job_name = "smartctl";
        scrape_interval = "1m";
        static_configs = [
          (mkConfig {
            hostname = "localhost";
            alias = "chopper";
            exporter = "smartctl";
          })
        ];
      }
      {
        job_name = "apcupsd";
        scrape_interval = "15s";
        static_configs = [
          (mkConfig {
            hostname = "localhost";
            alias = "chopper";
            exporter = "apcupsd";
          })
        ];
      }
      {
        job_name = "blocky";
        scrape_interval = "30s";
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
      {
        job_name = "pomerium";
        scrape_interval = "30s";
        static_configs = [
          {
            targets = [
              "pomerium:9091"
            ];
            labels = {
              alias = "pomerium";
            };
          }
        ];
      }
      {
        job_name = "kube-prom";
        scrape_interval = "30s";
        honor_labels = true;
        metrics_path = "/federate";
        params."match[]" = lib.singleton "{job!=\"\"}";
        scheme = "https";
        static_configs = [
          {
            targets = [
              "kube-prom.springhare-egret.ts.net"
            ];
            labels = {
              alias = "kube-prom";
            };
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      common = {
        instance_addr = "127.0.0.1";
        path_prefix = config.services.loki.dataDir;
        storage.filesystem = {
          chunks_directory = "${config.services.loki.dataDir}/chunks";
          rules_directory = "${config.services.loki.dataDir}/rules";
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };
      schema_config.configs = [
        {
          from = "2023-10-10";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v12";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      limits_config = {
        reject_old_samples = true;
        allow_structured_metadata = false;
      };
      table_manager = {
        retention_period = "168h";
      };
      analytics.reporting_enabled = false;
    };
  };

  services.promtail = with lib; {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      clients = singleton { url = "http://localhost:3100/loki/api/v1/push"; };
      scrape_configs = singleton {
        job_name = "chopper-journal";
        journal = {
          json = true;
          max_age = "12h";
          path = "/var/log/journal";
          labels = {
            job = "chopper-journal";
          };
        };
        relabel_configs = singleton {
          source_labels = singleton "__journal__systemd_unit";
          target_label = "unit";
        };
      };
    };
  };

  services.scrutiny = {
    enable = true;
    collector = {
      enable = true;
      settings = {
        api.endpoint = "http://localhost:${builtins.toString config.services.scrutiny.settings.web.listen.port}";
        devices =
          let
            drives = [
              "sda"
              "sdb"
              "sdc"
              "sdd"
              "sde"
              "sdf"
              "sdg"
            ];
          in
          map (drive: {
            device = "/dev/${drive}";
            type = "sat";
            commands = {
              metrics_smart_args = "-xv 188,raw16 --xall --json -T permissive";
            };
          }) drives;
      };
    };
    settings = {
      web.listen.port = 8082;
    };
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "prometheus.${domain}" = helpers.mkVirtualHost config.services.prometheus.port;
    "loki.${domain}" = helpers.mkVirtualHost 3100;
    "grafana.${domain}" = helpers.mkSocketVirtualHost "/run/grafana/grafana.sock";
    "scrutiny.${domain}" = helpers.mkVirtualHost config.services.scrutiny.settings.web.listen.port;
  };

}
