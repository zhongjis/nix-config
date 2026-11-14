{
  inputs,
  config,
  pkgs,
  lib,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  selectedSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
    harness = "claude-code";
  };

  # Convert commonInstructions (list of paths) to an attrset for `rules`
  # e.g. /nix/store/...-nix-environment.md → { "nix-environment" = /nix/store/...; }
  instructionRules = builtins.listToAttrs (map (path: let
      filename = builtins.baseNameOf (toString path);
      # Strip .md extension for the rule name
      name = lib.removeSuffix ".md" filename;
    in {
      inherit name;
      value = path;
    })
    commonInstructions);

  # Claude Code's Bash tool never runs a shell's direnv hook, so load the
  # allowed .envrc environment into CLAUDE_ENV_FILE on session start, on cd,
  # and when .envrc changes. direnv keeps refusing unallowed .envrc files.
  direnvHook = pkgs.writeShellScript "claude-direnv-hook" ''
    [ -n "''${CLAUDE_ENV_FILE:-}" ] || exit 0
    dir=$(${lib.getExe pkgs.jq} -r '.new_cwd // .cwd // empty')
    [ -n "$dir" ] && cd "$dir" || exit 0
    direnv export bash >> "$CLAUDE_ENV_FILE" 2>/dev/null || true
  '';
  direnvHookEntry = matcher:
    {
      hooks = [
        {
          type = "command";
          command = "${direnvHook}";
          timeout = 120;
        }
      ];
    }
    // lib.optionalAttrs (matcher != null) {inherit matcher;};
  direnvHooks = {
    SessionStart = direnvHookEntry null;
    CwdChanged = direnvHookEntry null;
    FileChanged = direnvHookEntry ".envrc";
  };
in {
  imports = [
    ../common/mcp
    ../common/agents
  ];

  # ICM is the memory store; disable Claude Code's built-in auto memory.
  home.sessionVariables.CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";

  # Keep long-running background watchers alive; Claude Code otherwise reaps
  # idle background shells under critical memory pressure (undocumented knob).
  home.sessionVariables.CLAUDE_CODE_DISABLE_BG_SHELL_PRESSURE_REAP = "1";

  # Keep settings.json writable and preserve settings managed by Claude Code and plugins.
  # Hide Claude Code's commit trailer and pull request footer (`attribution: false`).
  home.activation.claudeCodePermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.bash}/bin/bash -eu -c ${lib.escapeShellArg ''
      settings=${lib.escapeShellArg "${config.programs.claude-code.configDir}/settings.json"}
      mkdir -p "$(dirname "$settings")"
      temporary=$(mktemp "$settings.XXXXXX")
      trap 'rm -f "$temporary"' EXIT
      if [[ -e "$settings" ]]; then
        ${pkgs.jq}/bin/jq '.permissions.defaultMode = "bypassPermissions" | .attribution = false' "$settings" > "$temporary"
      else
        printf '%s\n' '{"permissions":{"defaultMode":"bypassPermissions"},"attribution":false}' > "$temporary"
      fi
      mv "$temporary" "$settings"
    ''}
  '';

  # Merge the direnv hooks into the writable settings.json, replacing earlier
  # generations of this hook and leaving every other hook untouched.
  home.activation.claudeCodeDirenvHooks = lib.hm.dag.entryAfter ["claudeCodePermissions"] ''
    run ${pkgs.bash}/bin/bash -eu -c ${lib.escapeShellArg ''
      settings=${lib.escapeShellArg "${config.programs.claude-code.configDir}/settings.json"}
      temporary=$(mktemp "$settings.XXXXXX")
      trap 'rm -f "$temporary"' EXIT
      ${lib.getExe pkgs.jq} --argjson add ${lib.escapeShellArg (builtins.toJSON direnvHooks)} '
        def isDirenv: any((.hooks // [])[]; (.command? // "") | type == "string" and endswith("-claude-direnv-hook"));
        reduce ($add | to_entries[]) as $e (.;
          .hooks[$e.key] = (((.hooks[$e.key] // []) | map(select(isDirenv | not))) + [$e.value]))
      ' "$settings" > "$temporary"
      if ! ${lib.getExe pkgs.jq} -e -n --slurpfile a "$settings" --slurpfile b "$temporary" '$a == $b' > /dev/null; then
        cat "$temporary" > "$settings"
      fi
    ''}
  '';

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = false;
    package = llmAgentsPackages.claude-code;
    icm.enable = true;
    rtk.enable = true;
    caveman = {
      enable = true;
      mode = "full";
    };
    skills = selectedSkills;
    # Research subagents adapted from humanlayer/humanlayer .claude/agents;
    # implementer subagents adapted from Pi jintong/yunu
    agentsDir = ./agents;

    # Use rules instead of settings.instructions so settings.json is not managed by HM
    rules = instructionRules // {"20-intent-gate" = ./rules/20-intent-gate.md;};
  };
}
