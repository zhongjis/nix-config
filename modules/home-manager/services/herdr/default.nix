{
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  herdrPkg = inputs.llm-agents.packages.${system}.herdr;
in {
  home.packages = [
    pkgs.jq # sessionizer parses `herdr workspace list` JSON
    (pkgs.writeScriptBin "sessionizer" ''
      ${builtins.readFile ./scripts/herdr-sessionizer.sh}
    '')
  ];

  programs.herdr = {
    enable = true;
    package = herdrPkg;
    settings = {
      onboarding = false;
      # Inherit the terminal's (stylix-managed) palette.
      theme.name = "terminal";
      terminal = {
        # Uses $SHELL (zsh); "auto" selects a login shell on macOS.
        shell_mode = "auto";
        # Inherit cwd from the source pane/workspace.
        new_cwd = "follow";
      };
      # Keep the default ctrl+b prefix, Vim pane navigation, and reload binding.
      keys.command = [
        {
          # Sessionizer: fzf project switcher — create/switch a workspace.
          key = "prefix+f";
          type = "pane";
          command = "sessionizer";
        }
      ];
      ui = {
        # Auto-name tabs; workspaces use the root pane's repo/folder.
        prompt_new_tab_name = false;
        # Surface agent state on split borders.
        show_agent_labels_on_pane_borders = true;
        # Cmd + right-click forwards to pane apps instead of the pane menu.
        right_click_passthrough_modifier = "cmd";
        toast = {
          # Deliver agent finished / needs-input popups via OS notifications.
          delivery = "system";
          herdr.position = "bottom-right";
        };
      };
      experimental.kitty_graphics = true;
      # Herdr counts scrollback in bytes (10 MB).
      advanced.scrollback_limit_bytes = 10000000;
    };
  };
}
