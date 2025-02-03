{
  config,
  lib,
  ...
}: {
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
      # web search
      ENABLE_RAG_WEB_SEARCH = "True";
      RAG_WEB_SEARCH_ENGINE = "searxng";
      RAG_WEB_SEARCH_RESULT_COUNT = "5";
      RAG_WEB_SEARCH_CONCURRENT_REQUESTS = "10";
      SEARXNG_QUERY_URL = "http://localhost:8081/search?q=<query>";
      # settings
      AUDIO_STT_ENGINE = "openai";
      AUDIO_STT_MODEL = "whisper-large-v3";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
    };
    environmentFile = config.sops.secrets."api_keys_for_ai".path;
  };

  services.searx = {
    enable = true;

    # Rate limiting
    limiterSettings = {
      botdetection.ip_limit.link_token = false;
      botdetection.ip_lists = {
        block_ip = [];
        pass_ip = [];
      };
    };

    # Uwsgi
    runInUwsgi = true;
    uwsgiConfig = {
      http = ":8081";
    };

    # settings
    settings = {
      # Instance settings
      general = {
        debug = false;
        instance_name = "SearXNG Instance";
        donation_url = false;
        contact_url = false;
        privacypolicy_url = false;
        enable_metrics = true;
      };

      # User interface
      ui = {
        query_in_title = true;
        results_on_new_tab = false;
        theme_args.simple_style = "black";
        infinite_scroll = true;
        static_use_hash = true;
      };

      # Search engine settings
      search = {
        safe_search = 0;
        autocomplete = "google";
        favicon_resolver = "google";
        formats = [
          "html"
          "json"
        ];
      };

      # Server configuration
      server = {
        port = 8081;
        bind_address = "127.0.0.1";
        secret_key = "who_cares_its_local";
        limiter = true;
        public_instance = false;
        image_proxy = true;
        method = "GET";
      };

      # Search engines
      engines = lib.mapAttrsToList (name: value: {inherit name;} // value) {
        "duckduckgo".disabled = false;
        "brave".disabled = true;
        "bing".disabled = false;
        "startpage".disabled = false;
        "mojeek".disabled = false;
        "mwmbl".disabled = false;
        "mwmbl".weight = 0.2;
        "qwant".disabled = true;
        "crowdview".disabled = false;
        "crowdview".weight = 0.5;
        "curlie".disabled = true;
        "ddg definitions".disabled = false;
        "ddg definitions".weight = 2;
        "wikibooks".disabled = false;
        "wikidata".disabled = false;
        "wikiquote".disabled = true;
        "wikisource".disabled = true;
        "wikispecies".disabled = true;
        "wikiversity".disabled = true;
        "wikivoyage".disabled = true;
        "currency".disabled = true;
        "dictzone".disabled = true;
        "lingva".disabled = true;
        "bing images".disabled = false;
        "brave.images".disabled = true;
        "duckduckgo images".disabled = true;
        "google images".disabled = false;
        "qwant images".disabled = true;
        "1x".disabled = true;
        "artic".disabled = false;
        "deviantart".disabled = false;
        "flickr".disabled = true;
        "frinklac".disabled = false;
        "imgur".disabled = false;
        "library of congress".disabled = false;
        "material icons".disabled = true;
        "material icons".weight = 0.2;
        "openverse".disabled = false;
        "pinterest".disabled = true;
        "svgrepo".disabled = false;
        "unsplash".disabled = false;
        "wallhaven".disabled = false;
        "wikicommons.images".disabled = false;
        "yacy images".disabled = true;
        "seekr images (EN)".disabled = true;
        "bing videos".disabled = false;
        "brave.videos".disabled = true;
        "duckduckgo videos".disabled = true;
        "google videos".disabled = false;
        "qwant videos".disabled = false;
        "bilibili".disabled = false;
        "ccc-tv".disabled = true;
        "dailymotion".disabled = true;
        "google play movies".disabled = true;
        "invidious".disabled = true;
        "odysee".disabled = true;
        "peertube".disabled = false;
        "piped".disabled = true;
        "rumble".disabled = false;
        "sepiasearch".disabled = false;
        "vimeo".disabled = true;
        "youtube".disabled = false;
        "mediathekviewweb (DE)".disabled = true;
        "seekr videos (EN)".disabled = true;
        "ina (FR)".disabled = true;
        "brave.news".disabled = true;
        "google news".disabled = true;
        "apple maps".disabled = false;
        "piped.music".disabled = true;
        "radio browser".disabled = true;
        "codeberg".disabled = true;
        "gitlab".disabled = false;
        "internetarchivescholar".disabled = true;
        "pdbe".disabled = true;
      };
      # Outgoing requests
      outgoing = {
        request_timeout = 5.0;
        max_request_timeout = 15.0;
        pool_connections = 100;
        pool_maxsize = 15;
        enable_http2 = true;
      };

      # Enabled plugins
      enabled_plugins = [
        "Basic Calculator"
        "Hash plugin"
        "Tor check plugin"
        "Open Access DOI rewrite"
        "Hostnames plugin"
        "Unit converter plugin"
        "Tracker URL remover"
      ];
    };
  };
}
