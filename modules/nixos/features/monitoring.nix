{config, ...}: {
  # original post: https://gist.github.com/rickhull/895b0cb38fdd537c1078a858cf15d63e
  # MONITORING: services run on loopback interface
  #             nginx reverse proxy exposes services to network
  #             - grafana:3010
  #             - prometheus:3020
  #             - loki:3030
  #             - promtail:3031

  # prometheus: port 3020 (8020)
  #
  services.prometheus = {
    port = 3020;
    enable = true;

    exporters = {
      node = {
        port = 3021;
        enabledCollectors = ["systemd"];
        enable = true;
      };
    };

    # ingest the published nodes
    scrapeConfigs = [
      {
        job_name = "nodes";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            ];
          }
        ];
      }
    ];
  };

  # loki: port 3030 (8030)
  #
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server.http_listen_port = 3030;

      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/var/lib/loki";
      };

      schema_config = {
        configs = [
          {
            from = "2020-05-15";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config = {
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
    };
  };

  # promtail: port 3031 (8031)
  #
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [
        {
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "pihole";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
      ];
    };
    # extraFlags
  };

  # grafana: port 3010 (8010)
  #
  services.grafana = {
    enable = true;

    settings.server = {
      http_port = 3010;
      http_addr = "127.0.0.1";
      domain = "grafana.zshen.me";
      protocol = "http";
    };

    settings.analytics = {
      reporting_enabled = false;
      feedback_links_enabled = false;
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };

  # nginx reverse proxy
  services.nginx = {
    upstreams = {
      "prometheus" = {
        servers = {
          "127.0.0.1:${toString config.services.prometheus.port}" = {};
        };
      };
      "loki" = {
        servers = {
          "127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}" = {};
        };
      };
      "promtail" = {
        servers = {
          "127.0.0.1:${toString config.services.promtail.configuration.server.http_listen_port}" = {};
        };
      };
    };

    # NOTE: expose grafana dashboard to internet
    virtualHosts."${config.services.grafana.settings.server.domain}" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
      };
    };

    virtualHosts.prometheus = {
      locations."/".proxyPass = "http://prometheus";
      listen = [
        {
          addr = "192.168.1.10";
          port = 8020;
        }
      ];
    };

    # confirm with http://192.168.1.10:8030/loki/api/v1/status/buildinfo
    #     (or)     /config /metrics /ready
    virtualHosts.loki = {
      locations."/".proxyPass = "http://loki";
      listen = [
        {
          addr = "192.168.1.10";
          port = 8030;
        }
      ];
    };

    virtualHosts.promtail = {
      locations."/".proxyPass = "http://promtail";
      listen = [
        {
          addr = "192.168.1.10";
          port = 8031;
        }
      ];
    };
  };
}
