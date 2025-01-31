{config, ...}: {
  # FIXME: broken
  # NOTE: the following command only work for linux
  services.podman.containers = {
    "open-webui" = {
      image = "ghcr.io/open-webui/open-webui:main";
      volumes = ["open-webui:/app/backend/data"];
      ports = ["3000:8080"];
      environment = {
        # basic
        WEBUI_SECRET_KEY = "";
        WEBUI_AUTH = "False";
        # openai # moved to env file
        # OPENAI_API_KEY = "";
        # ollama
        OLLAMA_BASE_URL = "http://host.docker.internal:11434";
        # searxng
        ENABLE_RAG_WEB_SEARCH = "True";
        RAG_WEB_SEARCH_ENGINE = "searxng";
        RAG_WEB_SEARCH_RESULT_COUNT = 0;
        RAG_WEB_SEARCH_CONCURRENT_REQUESTS = 5;
        SEARXNG_QUERY_URL = "http://host.docker.internal:8081/search?q=<query>";
        ANONYMIZED_TELEMETRY = "False";
      };
      extraPodmanArgs = [
        "--network=pasta:--map-gw"
        "--add-host=localhost:127.0.0.1"
      ];
      environmentFile = [config.sops.secrets."api_keys_for_ai".path];
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
}
