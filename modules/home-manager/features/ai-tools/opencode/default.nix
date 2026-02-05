{
  config,
  inputs,
  pkgs,
  lib,
  aiProfileHelpers,
  ...
}: {
  imports = [
    ../general
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
        "${./instructions/shell-strategy.md}"
        "${../general/instructions/nix-environment.md}"
      ];

      permission.skill =
        {
          "general-*" = "allow";
        }
        // lib.optionalAttrs aiProfileHelpers.isWork {
          "work-*" = "allow";
        }
        // lib.optionalAttrs aiProfileHelpers.isPersonal {
          "personal-*" = "allow";
        };
    };
  };

  home.sessionVariables = {
    OPENCODE_DISABLE_CLAUDE_CODE = "1";
  };
}
