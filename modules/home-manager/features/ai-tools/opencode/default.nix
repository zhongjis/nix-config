{
  inputs,
  pkgs,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  selectedSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
    harness = "opencode";
  };
in {
  imports = [
    ../common
    ./agents
    ./formatters.nix
    ./permission.nix
    ./provider.nix
    ./lsp.nix
    ./plugins
  ];

  home.packages = [
    llmAgentsPackages.oh-my-opencode
    # opencode 2 CLI, available as `opencode2` alongside the v1 `opencode`.
    # ponytail: coexist only. Full migration (programs.opencode.package = opencode2)
    # is blocked until oh-my-opencode + plugins ship v2-SDK builds; v1 plugins do not run in v2.
    llmAgentsPackages.opencode2
  ];

  programs.opencode = {
    enable = true;
    package = llmAgentsPackages.opencode;
    web.enable = false;
    enableMcpIntegration = true;
    caveman = {
      enable = true;
      mode = "ultra";
    };
    rtk.enable = true;
    skills = selectedSkills;

    settings = {
      share = "disabled";
      autoupdate = false;
      snapshot = false;

      instructions =
        commonInstructions
        ++ [
          "${./instructions/shell-strategy.md}"
        ];
    };
  };

  home.sessionVariables = {
    OPENCODE_DISABLE_CLAUDE_CODE = "1";
    OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
  };
}
