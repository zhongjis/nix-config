{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../shared
    ../opencode-only
    ./lsp.nix
    ./agents
    ./formatters.nix
    ./permission.nix
    ./provider.nix
    ./plugins
  ];

  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
    enableMcpIntegration = true;

    settings = {
      share = "disabled";
      autoupdate = false;

      tui = {
        scroll_accelaeration = {
          enabled = true;
        };
        diff_style = "stacked";
      };

      instructions = [
        "${../opencode-only/instructions/shell-strategy.md}"
        "${../shared/instructions/nix-environment.md}"
      ];
    };
  };

  home.sessionVariables = {
    OPENCODE_DISABLE_CLAUDE_CODE_SKILLS = 1;
  };
}
