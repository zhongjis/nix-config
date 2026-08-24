{
  pkgs,
  lib,
  config,
  hasPlugin,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  cfg = config.programs.opencode.ohMyOpenCode;

  sharedConfig = {
    "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json";
    _migrations = [
      "2026-07-opencode-config-unification"
      "2026-07-codex-config-jsonc"
      "2026-08-reasoning-unification"
    ];
    profiles = {};

    "[opencode]" = {
      # Impeccable enforcement
      categories.visual-engineering.prompt_append = "Always load and follow the impeccable skill for UI/UX design and implementation work.";

      # Disable all Claude Code compatibility features
      claude_code = {
        mcp = false;
        skills = false;
        agents = false;
        commands = false;
        plugins = false;
        hooks = false;
      };

      disabled_skills = ["playwright" "frontend"];
      disabled_hooks = ["comment-checker"];

      hashline_edit = true;

      team_mode = {
        enabled = true;
        tmux_visualization = false;
        max_parallel_members = 4;
        max_members = 8;
        max_messages_per_run = 10000;
        max_wall_clock_minutes = 120;
        max_member_turns = 500;
        message_payload_max_bytes = 32768;
        recipient_unread_max_bytes = 262144;
        mailbox_poll_interval_ms = 3000;
      };

      runtime_fallback = true;

      git_master = {
        commit_footer = false;
        include_co_authored_by = false;
        git_env_prefix = "GIT_MASTER=1";
      };

      browser_automation_engine.provider = "agent-browser";
    };
  };
in {
  options.programs.opencode.ohMyOpenCode = {
    settings = lib.mkOption {
      type = jsonFormat.type;
      default = {};
      description = ''
        Oh My OpenAgent unified configuration attrset.
        This will be serialized to JSON and placed at ~/.omo/omo.jsonc.
        Other plugin modules can merge additional settings into this option.
      '';
    };
  };

  config = lib.mkIf (hasPlugin "oh-my-opencode") {
    programs.opencode.ohMyOpenCode.settings = sharedConfig;

    # Force replacement of OMO's mutable migration output with a Nix store symlink.
    home.file.".omo/omo.jsonc" = {
      text = builtins.toJSON cfg.settings;
      force = true;
    };
  };
}
