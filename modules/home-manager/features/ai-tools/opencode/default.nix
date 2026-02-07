{
  config,
  inputs,
  pkgs,
  lib,
  aiProfileHelpers,
  commonInstructions,
  ...
}: {
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

  programs.opencode = {
    enable = true;
    package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
    web.enable = false;
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

      instructions =
        commonInstructions
        ++ [
          "${./instructions/shell-strategy.md}"
        ];

      permission.skill =
        {
          # general-* skills from both common/skills/ and opencode/skills/
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
