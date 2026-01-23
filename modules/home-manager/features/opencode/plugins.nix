{lib, ...}: let
  pluginList = [
    "@simonwjackson/opencode-direnv@latest"
    "oh-my-opencode@3.0.0-beta.13"
    "opencode-google-antigravity-auth@latest"
  ];

  hasAntigravityAuth = lib.any (p: builtins.match ".*antigravity-auth.*" p != null) pluginList;
  hasOhMyOpencode = lib.any (p: builtins.match ".*oh-my-opencode.*" p != null) pluginList;
in {
  programs.opencode.settings = {
    plugin = pluginList;
  };

  # NOTE: only available when antigravity-auth plugin exists
  programs.opencode.settings.provider.google = lib.mkIf hasAntigravityAuth {
    models = {
      "antigravity-gemini-3-pro" = {
        name = "Gemini 3 Pro (Antigravity)";
        limit = {
          context = 1048576;
          output = 65535;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {
            thinkingLevel = "low";
          };
          high = {
            thinkingLevel = "high";
          };
        };
      };
      "antigravity-gemini-3-flash" = {
        name = "Gemini 3 Flash (Antigravity)";
        limit = {
          context = 1048576;
          output = 65536;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          minimal = {
            thinkingLevel = "minimal";
          };
          low = {
            thinkingLevel = "low";
          };
          medium = {
            thinkingLevel = "medium";
          };
          high = {
            thinkingLevel = "high";
          };
        };
      };
      "antigravity-claude-sonnet-4-5" = {
        name = "Claude Sonnet 4.5 (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
      };
      "antigravity-claude-sonnet-4-5-thinking" = {
        name = "Claude Sonnet 4.5 Thinking (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {
            thinkingConfig = {
              thinkingBudget = 8192;
            };
          };
          max = {
            thinkingConfig = {
              thinkingBudget = 32768;
            };
          };
        };
      };
      "antigravity-claude-opus-4-5-thinking" = {
        name = "Claude Opus 4.5 Thinking (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {
            thinkingConfig = {
              thinkingBudget = 8192;
            };
          };
          max = {
            thinkingConfig = {
              thinkingBudget = 32768;
            };
          };
        };
      };
      "gemini-2.5-flash" = {
        name = "Gemini 2.5 Flash (Gemini CLI)";
        limit = {
          context = 1048576;
          output = 65536;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
      };
      "gemini-2.5-pro" = {
        name = "Gemini 2.5 Pro (Gemini CLI)";
        limit = {
          context = 1048576;
          output = 65536;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
      };
      "gemini-3-flash-preview" = {
        name = "Gemini 3 Flash Preview (Gemini CLI)";
        limit = {
          context = 1048576;
          output = 65536;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
      };
      "gemini-3-pro-preview" = {
        name = "Gemini 3 Pro Preview (Gemini CLI)";
        limit = {
          context = 1048576;
          output = 65535;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
      };
    };
  };

  xdg.configFile = lib.mkIf hasOhMyOpencode {
    # "opencode/oh-my-opencode.json".source = ./oh-my-opencode/cheap-but-not-free.json;
    "opencode/oh-my-opencode.json".source = ./oh-my-opencode/poorman-pretends-rich.json;
  };
}
