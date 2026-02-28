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
    package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
      postPatch =
        (oldAttrs.postPatch or "")
        + ''
          # Patch out bun version check - opencode v1.2.15 packageManager requires ^1.3.10
          # but nixpkgs only has bun 1.3.9. Remove once nixpkgs bun >= 1.3.10
          sed -i '/semver\.satisfies(process\.versions\.bun/,/^[[:space:]]*}/s/.*//' packages/script/src/index.ts
        '';
    });
    web.enable = false;
    enableMcpIntegration = true;

    settings = {
      share = "disabled";
      autoupdate = false;

      tui = {
        scroll_acceleration.enabled = true;
        diff_style = "stacked";
      };

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
  };
}
