{
  config,
  inputs,
  lib,
  pkgs,
  aiProfileHelpers,
  commonInstructions,
  ...
}: let
  aiCfg = config.myHomeManager.ai-tools;
  llmAgentsPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # Adapted from the block `codegraph install` writes into agent instruction files.
  codegraphContext = ''
    ## CodeGraph

    In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

    - **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source.
    - **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

    If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
  '';
in {
  config = lib.mkIf (aiCfg.enable && aiCfg.agy.enable) {
    # Upstream Home Manager module. Writes rules to ~/.gemini/GEMINI.md (agy's
    # legacy rules path), skills to ~/.gemini/antigravity-cli/skills/, and MCP
    # servers to ~/.gemini/config/mcp_config.json. `settings` stays unset:
    # agy rewrites ~/.gemini/antigravity-cli/settings.json at runtime, so
    # `managedSettings` (custom-home-manager-options/antigravity-cli) merges into it.
    programs.antigravity-cli = {
      enable = true;
      package = llmAgentsPackages.antigravity-cli;
      context.GEMINI = lib.mkMerge [
        (builtins.concatStringsSep "\n\n" (map builtins.readFile commonInstructions))
        (lib.mkAfter codegraphContext)
      ];
      skills = inputs.agent-skills.lib.skillsFor {
        profile = aiProfileHelpers.profile;
        harness = "agy";
      };
      enableMcpIntegration = true;
      mcpServers.codegraph = {
        command = lib.getExe llmAgentsPackages.codegraph;
        args = ["serve" "--mcp"];
      };
      icm.enable = true;
      managedSettings = {
        "$schema" = "https://antigravity.google/schemas/v1/settings.json";
        # Runs tools without prompts or terminal sandboxing (YOLO mode, matching
        # Claude Code's bypassPermissions); permissions.deny below still applies.
        toolPermission = "always-proceed";
        enableTerminalSandbox = false;
        allowNonWorkspaceAccess = true;
        # Kept so NixOS commands still work if the terminal sandbox is enabled ad hoc.
        permissions.allow = [
          "read_file(/nix/store)"
          "read_file(/run/current-system)"
        ];
        # Deny beats every toolPermission mode; keeps secrets out of model context.
        permissions.deny =
          map (path: "read_file(${path})") [
            "${config.home.homeDirectory}/.ssh"
            "${config.home.homeDirectory}/.config/sops/age"
            "${config.home.homeDirectory}/.aws"
            # Rules match the resolved path, and ~/.ssh keys link into sops-nix secrets.
            config.sops.defaultSymlinkPath
          ]
          # sops-nix mounts decrypted secrets under the runtime dir (/run/user/<uid>).
          ++ lib.optional pkgs.stdenv.hostPlatform.isLinux "read_file(/run/user)";
      };
    };

    # The Nix store binary cannot update itself.
    home.sessionVariables.AGY_CLI_DISABLE_AUTO_UPDATE = "true";
  };
}
