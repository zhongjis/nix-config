{
  inputs,
  pkgs,
  commonInstructions,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  selfPackages = inputs.self.packages.${system};
in {
  imports = [
    ../common
    ./skills
    ./agents
    ./formatters.nix
    ./permission.nix
    ./provider.nix
    ./lsp.nix
    ./plugins
  ];

  home.packages = [
    selfPackages.oh-my-opencode
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
    impeccable.enable = true;
    rtk.enable = true;

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
