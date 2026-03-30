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
    disabled_hooks = ["comment-checker" "startup-toast"];

    sisyphus = {
      tasks = {
        enabled = true;
        claude_code_compat = false;
      };
    };

    # others
    browser_automation_engine.provider = "agent-browser";
    tmux = {enabled = false;};
    google_auth = false;
    hashline_edit = true;
  };

  # Profile-specific overrides
  # Providers: GitHub Copilot, OpenCode Zen
  # Based on oh-my-opencode official model-requirements.ts recommendations
  personalOverrides = {
    runtime_fallback.enabled = true;
    agents = {
      sisyphus.model = "openai/gpt-5.4";
      metis.model = "openai/gpt-5.4";

      prometheus.model = "openai/gpt-5.4";
      atlas.model = "openai/gpt-5.4";

      hephaestus.model = "openai/gpt-5.3-codex";
      oracle.model = "openai/gpt-5.4";
      momus.model = "openai/gpt-5.4";

      multimodal-looker.model = "openai/gpt-5.4";
      librarian.model = "opencode/minimax-m2.5";
      explore.model = "github-copilot/grok-code-fast-1";
    };
    categories = {
      visual-engineering.model = "github-copilot/gemini-3.1-pro-preview";
      ultrabrain.model = "openai/gpt-5.4";
      deep.model = "openai/gpt-5.3-codex";

      artistry.model = "github-copilot/gemini-3.1-pro-preview";
      quick.model = "github-copilot/gpt-5.4-mini";
      unspecified-high.model = "openai/gpt-5.4";
      unspecified-low.model = "github-copilot/claude-sonnet-4.6";
      writing.model = "github-copilot/gemini-3-flash-preview";
    };
  };

  workOverrides = {
    # --- mixed GitHub Copilot + Bedrock (Anthropic) + openai configuration ---
    agents = {
      sisyphus.model = "openai/gpt-5.4";
      metis.model = "openai/gpt-5.4";

      prometheus.model = "openai/gpt-5.4";
      atlas.model = "openai/gpt-5.4";

      hephaestus.model = "openai/gpt-5.4";
      oracle.model = "openai/gpt-5.4";
      momus.model = "openai/gpt-5.4";

      multimodal-looker.model = "openai/gpt-5.3-codex";
      librarian.model = "github-copilot/gemini-3-flash-preview";
      explore.model = "github-copilot/claude-haiku-4.5";
    };
    categories = {
      visual-engineering.model = "github-copilot/gemini-3.1-pro-preview";

      ultrabrain.model = "openai/gpt-5.3-codex";
      deep.model = "openai/gpt-5.3-codex";

      artistry.model = "github-copilot/gemini-3.1-pro-preview";
      quick.model = "openai/gpt-5.4-mini";
      unspecified-high.model = "openai/gpt-5.4";
      unspecified-low.model = "github-copilot/claude-sonnet-4.6";
      writing.model = "github-copilot/gemini-3-flash-preview";
    };

    git_master = {
      commit_footer = false;
      include_co_authored_by = false;
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
