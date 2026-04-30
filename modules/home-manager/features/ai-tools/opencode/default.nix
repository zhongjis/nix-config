{
  inputs,
  pkgs,
  commonInstructions,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
in {
  imports = [
    ../common
    ./skills
    ./lsp.nix
    ./agents
    ./formatters.nix
    ./permission.nix
    ./provider.nix
    ./plugins
  ];

  home.packages = [
    llmAgentsPackages.oh-my-opencode
  ];

  programs.opencode = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    web.enable = false;
    enableMcpIntegration = true;
    impeccable.enable = true;
    rtk.enable = true;

    settings = {
      share = "disabled";
      autoupdate = false;

      instructions =
        commonInstructions
        ++ [
          "${./instructions/shell-strategy.md}"
        ];

      permission.skill = {
        # Allow all provisioned skills (filtering is handled by commonSkills based on aiProfile)
        "*" = "allow";
      };
    };
  };

  home.sessionVariables = {
    OPENCODE_DISABLE_CLAUDE_CODE = "1";
    OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
  };
}
