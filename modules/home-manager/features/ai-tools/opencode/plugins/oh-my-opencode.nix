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
    "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";
    agents = {
      sisyphus.model = "github-copilot/claude-opus-4.6";
      oracle.model = "github-copilot/gpt-5.2";
      multimodal-looker.model = "github-copilot/gemini-3-flash-preview";
      prometheus.model = "github-copilot/claude-opus-4.6";
      momus.model = "github-copilot/claude-opus-4.6";
    };
    categories = {
      visual-engineering.model = "github-copilot/gemini-3-pro-preview";
      ultrabrain.model = "github-copilot/gpt-5.2-codex";
      artistry.model = "github-copilot/gemini-3-pro-preview";
      quick.model = "github-copilot/claude-haiku-4.5";
      unspecified-high.model = "github-copilot/claude-opus-4.6";
      writing.model = "github-copilot/gemini-3-flash-preview";
    };
    disabled_skills = ["playwright"];
    browser_automation_engine.provider = "agent-browser";
    tmux = {
      enabled = true;
      layout = "main-vertical";
      main_pane_size = 60;
      main_pane_min_width = 120;
      agent_pane_min_width = 40;
    };
  };

  # Profile-specific overrides
  personalOverrides = {
    agents = {
      librarian = {
        prompt_append = "Always use the nixos-mcp for Nix related documentation lookups.";
        model = "opencode/glm-4.7";
      };
      explore.model = "github-copilot/grok-code-fast-1";
      metis.model = "opencode/kimi-k2.5";
      atlas.model = "opencode/kimi-k2.5";
    };
    categories = {
      unspecified-low.model = "opencode/kimi-k2.5";
    };
  };

  workOverrides = {
    agents = {
      librarian = {
        prompt_append = "Always use the nixos-mcp for Nix related documentation lookups.";
        model = "github-copilot/gemini-2.5-pro";
      };
      explore.model = "github-copilot/claude-haiku-4.6";
      metis.model = "github-copilot/claude-sonnet-4.6";
      atlas.model = "github-copilot/claude-sonnet-4.6";
    };
    categories = {
      unspecified-low.model = "github-copilot/claude-sonnet-4.6";
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
        ~/.config/opencode/oh-my-opencode.jsonc.
        Other plugin modules can merge additional settings into this option.
      '';
    };
  };

  config = lib.mkIf (hasPlugin "oh-my-opencode") {
    # Set the base configuration
    programs.opencode.ohMyOpenCode.settings = baseConfig;

    # Generate oh-my-opencode.jsonc from the final merged attrset
    xdg.configFile."opencode/oh-my-opencode.jsonc".text =
      builtins.toJSON cfg.settings;
  };
}
