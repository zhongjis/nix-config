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
in {
  imports = [
    ../common/mcp
    ../common/agents
  ];

  # ICM is the memory store; disable Claude Code's built-in auto memory.
  home.sessionVariables.CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";

  # Keep settings.json writable and preserve settings managed by Claude Code and plugins.
  home.activation.claudeCodePermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.bash}/bin/bash -eu -c ${lib.escapeShellArg ''
      settings=${lib.escapeShellArg "${config.programs.claude-code.configDir}/settings.json"}
      mkdir -p "$(dirname "$settings")"
      temporary=$(mktemp "$settings.XXXXXX")
      trap 'rm -f "$temporary"' EXIT
      if [[ -e "$settings" ]]; then
        ${pkgs.jq}/bin/jq '.permissions.defaultMode = "bypassPermissions"' "$settings" > "$temporary"
      else
        printf '%s\n' '{"permissions":{"defaultMode":"bypassPermissions"}}' > "$temporary"
      fi
      mv "$temporary" "$settings"
    ''}
  '';

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = false;
    package = llmAgentsPackages.claude-code;
    icm.enable = true;
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
