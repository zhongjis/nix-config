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
      librarian.prompt_append = "Always use the nixos-mcp for Nix related documentation lookups.";
    };
    # Disable all Claude Code compatibility features —
    # prevents oh-my-opencode from loading MCPs, skills, agents,
    # commands, plugins, and hooks from ~/.claude/
    claude_code = {
      mcp = false;
      skills = true;
      agents = true;
      commands = false;
      plugins = false;
      hooks = false;
    };
    disabled_skills = ["playwright"];
    browser_automation_engine.provider = "agent-browser";
    tmux = {
      enabled = false;
      layout = "main-vertical";
      main_pane_size = 60;
      main_pane_min_width = 120;
      agent_pane_min_width = 40;
    };
  };

  # Profile-specific overrides
  # Providers: GitHub Copilot, OpenCode Zen
  # Based on oh-my-opencode official model-requirements.ts recommendations
  personalOverrides = {
    runtime_fallback.enabled = true;
    agents = {
      # claude family
      sisyphus.model = "github-copilot/claude-opus-4.6";
      metis.model = "github-copilot/claude-opus-4.6";

      # gpt/claude dual
      prometheus.model = "github-copilot/claude-opus-4.6";
      atlas.model = "kimi-for-coding/k2p5";
      # atlas.model = "opencode/kimi-k2.5";

      # deep/gpt
      hephaestus.model = "openai/gpt-5.3-codex";
      oracle.model = "openai/gpt-5.4";
      momus.model = "openai/gpt-5.4";

      # utility
      # multimodal-looker.model = "opencode/kimi-k2.5";
      multimodal-looker.model = "openai/gpt-5.4";
      # librarian.model = "github-copilot/gemini-3-flash-preview";
      librarian.model = "google/antigravity-gemini-3-flash";
      explore.model = "github-copilot/claude-haiku-4.5";
    };
    categories = {
      # visual-engineering.model = "github-copilot/gemini-3.1-pro-preview";
      visual-engineering.model = "google/antigravity-gemini-3.1-pro";
      ultrabrain.model = "openai/gpt-5.3-codex";
      deep.model = "openai/gpt-5.3-codex";
      # artistry.model = "github-copilot/gemini-3.1-pro-preview";
      artistry.model = "google/antigravity-gemini-3.1-pro";
      quick.model = "github-copilot/claude-haiku-4.5";
      unspecified-high.model = "openai/gpt-5.4";
      unspecified-low.model = "github-copilot/claude-sonnet-4.6";
      # writing.model = "github-copilot/gemini-3-flash-preview";
      writing.model = "google/antigravity-gemini-3-flash";
    };
    google_auth = false;
  };

  workOverrides = {
    git_master = {
      commit_footer = false;
      include_co_authored_by = false;
    };

    # --- mixed GitHub Copilot + Bedrock (Anthropic) + openai configuration ---
    agents = {
      sisyphus.model = "openai/gpt-5.4";
      metis.model = "openai/gpt-5.4";

      prometheus.model = "openai/gpt-5.4";
      atlas.model = "github-copilot/claude-sonnet-4.6";
      unspecified-low.model = "github-copilot/claude-sonnet-4.6";

      hephaestus.model = "openai/gpt-5.3-codex";
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
      quick.model = "github-copilot/claude-haiku-4.5";
      unspecified-high.model = "openai/gpt-5.4";
      unspecified-low.model = "github-copilot/claude-sonnet-4.6";
      writing.model = "github-copilot/gemini-3-flash-preview";
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
