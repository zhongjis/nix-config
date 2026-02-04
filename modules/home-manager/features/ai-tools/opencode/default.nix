{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./lsp.nix
    ./skills
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
      autoshare = false;
      autoupdate = false;

      tui = {
        scroll_accelaeration = {
          enabled = true;
        };
        diff_style = "stacked";
      };

      instructions = [
        "${./instructions/shell-strategy.md}"
        "${./instructions/nix-environment.md}"
      ];
    };
  };

  home.sessionVariables = {
    OPENCODE_DISABLE_CLAUDE_CODE_SKILLS = 1;
  };
}
