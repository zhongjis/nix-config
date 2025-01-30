{pkgs, ...}: {
  home.packages = with pkgs; [
    passt
  ];

  services.podman = {
    enable = true;
    enableTypeChecks = true;
    autoUpdate.enable = true;
    networks.shared = {
      autoStart = true;
      description = "Default network to be shared";
      subnet = "192.168.20.0/24";
      gateway = "192.168.20.1";
      driver = "bridge";
      internal = false;
      extraPodmanArgs = [
        "--ipam-driver host-local"
      ];
    };

    # NOTE: the following command only work for linux
    containers = {
      "open-webui" = {
        image = "ghcr.io/open-webui/open-webui:main";
        volumes = ["open-webui:/app/backend/data"];
        ports = ["3000:8080"];
        environment = {
          # basic
          WEBUI_SECRET_KEY = "";
          WEBUI_AUTH = "False";
          # openai
          OPENAI_API_KEY = "";
          # ollama
          OLLAMA_BASE_URL = "http://host.docker.internal:11434";
          # searxng
          ENABLE_RAG_WEB_SEARCH = "True";
          RAG_WEB_SEARCH_ENGINE = "searxng";
          RAG_WEB_SEARCH_RESULT_COUNT = 0;
          RAG_WEB_SEARCH_CONCURRENT_REQUESTS = 5;
          SEARXNG_QUERY_URL = "http://host.docker.internal:8081/search?q=<query>";
        };
        extraPodmanArgs = [
          "--network=slirp4netns:allow_host_loopback=true"
        ];
        network = ["shared"];
        autoStart = true;
        autoUpdate = "registry";
      };

      "pipelines" = {
        image = "ghcr.io/open-webui/pipelines:main";
        volumes = ["pipelines:/app/pipelines"];
        ports = ["9099:9099"];
        environment = {
          PIPELINES_URLS = "https://github.com/open-webui/pipelines/blob/main/examples/pipelines/providers/anthropic_manifold_pipeline.py";
        };
        network = ["shared"];
        autoStart = true;
        autoUpdate = "registry";
      };

      "searxng" = {
        image = "searxng/searxng:latest";
        volumes = ["searxng:/etc/searxng"];
        ports = ["8081:8080"];
        network = ["shared"];
        autoStart = true;
        autoUpdate = "registry";
      };
    };
  };
}
