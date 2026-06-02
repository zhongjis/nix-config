{
  pkgs,
  lib,
  config,
  hasPlugin,
  aiProfileHelpers,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  cfg = config.programs.opencode.ohMyOpenCode;

  # Base oh-my-opencode configuration shared between profiles
  sharedConfig = {
    "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

    # Impeccable enforcement
    agents.artistry.prompt_append = "Always use impeccable skill for UI work";

    # Disable all Claude Code compatibility features
    claude_code = {
      mcp = false;
      skills = false;
      agents = false;
      commands = false;
      plugins = false;
      hooks = false;
    };

    # skills and hooks
    disabled_skills = ["playwright" "frontend-ui-ux"];
    disabled_hooks = ["comment-checker"];

    # hashline edit
    hashline_edit = true;

    # team mode
    team_mode = {
      enabled = true;
      max_parallel_members = 4;
      max_members = 8;
      tmux_visualization = false;
    };

    # git master
    git_master = {
      commit_footer = false;
      include_co_authored_by = false;
    };

    # others
    browser_automation_engine.provider = "agent-browser";
  };

  # Profile-specific overrides
  # Providers: GitHub Copilot, OpenCode Zen
  # Based on oh-my-opencode official model-requirements.ts recommendations
  personalOverrides = {
    runtime_fallback.enabled = true;
    agents = {
      sisyphus = {
        model = "openai/gpt-5.5";
        variant = "medium";
      };
      metis = {
        model = "openai/gpt-5.5";
        variant = "xhigh";
        # model = "github-copilot/claude-opus-4.8";
        # variant = "max";
      };

      prometheus = {
        model = "openai/gpt-5.5";
        variant = "high";
      };
      atlas = {
        model = "openai/gpt-5.5";
        variant = "medium";
      };

      hephaestus = {
        model = "openai/gpt-5.5";
        variant = "medium";
      };
      oracle = {
        model = "openai/gpt-5.5";
        variant = "high";
      };
      momus = {
        model = "openai/gpt-5.5";
        variant = "xhigh";
      };

      multimodal-looker = {
        model = "openai/gpt-5.5";
        variant = "medium";
      };
      librarian.model = "openai/gpt-5.4-mini-fast";
      explore.model = "openai/gpt-5.4-mini-fast";
    };
    categories = {
      visual-engineering = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
      };
      ultrabrain = {
        model = "openai/gpt-5.5";
        variant = "xhigh";
      };
      deep = {
        model = "openai/gpt-5.5";
        variant = "medium";
      };
      artistry = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
      };
      quick.model = "openai/gpt-5.4-mini";
      unspecified-high = {
        model = "openai/gpt-5.5";
        variant = "xhigh";
      };
      unspecified-low.model = "github-copilot/claude-sonnet-4.6";
      writing.model = "github-copilot/gemini-3.5-flash";
    };
  };

  workOverrides = {
    # --- mixed GitHub Copilot + Bedrock (Anthropic) + openai configuration ---
    runtime_fallback.enabled = true;
    agents = {
      sisyphus = {
        model = "anthropic/claude-opus-4-8";
        variant = "max";
        fallback_models = [
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      metis = {
        model = "github-copilot/claude-opus-4.8";
        variant = "max";
        fallback_models = [
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };

      prometheus = {
        model = "anthropic/claude-opus-4-8";
        variant = "max";
        fallback_models = [
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      atlas = {
        model = "anthropic/claude-sonnet-4-6";
        variant = "medium";
        fallback_models = [
          {
            model = "amazon-bedrock/us.anthropic.claude-sonnet-4-6";
            variant = "medium";
          }
        ];
      };

      hephaestus.disabled = true;

      oracle = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
        fallback_models = [
          {
            model = "anthropic/claude-opus-4-8";
            variant = "max";
          }
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      momus = {
        model = "anthropic/claude-opus-4-8";
        variant = "max";
        fallback_models = [
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };

      multimodal-looker = {
        model = "github-copilot/gpt-5.5";
        variant = "medium";
      };
      librarian = {
        model = "github-copilot/gpt-5.4-mini-fast";
        fallback_models = [
          {model = "anthropic/claude-haiku-4-5";}
          {model = "amazon-bedrock/us.anthropic.claude-haiku-4-5";}
        ];
      };
      explore = {
        model = "anthropic/claude-haiku-4-5";
        fallback_models = [
          {model = "amazon-bedrock/us.anthropic.claude-haiku-4-5";}
        ];
      };
    };
    categories = {
      visual-engineering = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
        fallback_models = [
          {
            model = "anthropic/claude-opus-4-8";
            variant = "max";
          }
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      ultrabrain = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
        fallback_models = [
          {
            model = "anthropic/claude-opus-4-8";
            variant = "max";
          }
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      deep = {
        model = "anthropic/claude-opus-4-8";
        variant = "max";
        fallback_models = [
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      artistry = {
        model = "github-copilot/gemini-3.1-pro-preview";
        variant = "high";
        fallback_models = [
          {
            model = "anthropic/claude-opus-4-8";
            variant = "max";
          }
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      quick = {
        model = "anthropic/claude-haiku-4-5";
        fallback_models = [
          {model = "amazon-bedrock/us.anthropic.claude-haiku-4-5";}
        ];
      };
      unspecified-high = {
        model = "anthropic/claude-opus-4-8";
        variant = "max";
        fallback_models = [
          {
            model = "amazon-bedrock/us.anthropic.claude-opus-4-8";
            variant = "max";
          }
        ];
      };
      unspecified-low = {
        model = "anthropic/claude-sonnet-4-6";
        fallback_models = [{model = "amazon-bedrock/us.anthropic.claude-sonnet-4-6";}];
      };
      writing = {
        model = "github-copilot/gemini-3-flash-preview";
        fallback_models = [{model = "amazon-bedrock/us.anthropic.claude-sonnet-4-6";}];
      };
    };
  };

  profileOverrides =
    if aiProfileHelpers.isWork
    then workOverrides
    else personalOverrides;

  baseConfig = lib.recursiveUpdate sharedConfig profileOverrides;
in {
  options.programs.opencode.ohMyOpenCode = {
    settings = lib.mkOption {
      type = jsonFormat.type;
      default = {};
      description = ''
        Oh My OpenCode configuration attrset.
        This will be serialized to JSON and placed at
        ~/.config/opencode/oh-my-openagent.jsonc.
        Other plugin modules can merge additional settings into this option.
      '';
    };
  };

  config = lib.mkIf (hasPlugin "oh-my-opencode") {
    # Set the base configuration
    programs.opencode.ohMyOpenCode.settings = baseConfig;

    # Generate oh-my-openagent.jsonc from the final merged attrset
    xdg.configFile."opencode/oh-my-openagent.jsonc".text =
      builtins.toJSON cfg.settings;
  };
}
