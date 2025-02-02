{config, ...}: {
  services.open-webui = {
    enable = true;
    port = 3000;
    environment = {
      # basic
      WEBUI_SECRET_KEY = "";
      WEBUI_AUTH = "False";
      # ollama
      OLLAMA_BASE_URL = "http://localhost:11434";
      ANONYMIZED_TELEMETRY = "False";
    };
    environmentFile = config.sops.secrets."api_keys_for_ai".path;
  };
}
