{
  pkgs,
  config,
  lib,
  currentSystemName,
  ...
}: let
in {
  home.file = {
    ".local/share/zsh/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    ".local/share/zsh/zsh-fast-syntax-highlighting".source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    ".local/share/zsh/zsh-vi-mode".source = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
  };

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    history = {
      ignoreDups = true;
      expireDuplicatesFirst = true;
      extended = true;
      save = 10000;
      size = 10000;
    };
    shellAliases = {
      cat = "bat -p";
      tree = "eza --color=auto --tree";
      grep = "grep --color=auto";
    };

    initContent = let
      initExtra =
        lib.mkOrder 1000
        /*
        bash
        */
        ''
          source "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

          source "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

          ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#${config.lib.stylix.colors.base03},bg=cyan,bold,underline"
          source "$HOME/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

          source "${./adobe.sh}"
        '';

      # Load before fzf to resolve conflicting shortcuts
      initExtraBeforeCompInit =
        lib.mkOrder 550
        /*
        bash
        */
        ''
          source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

          # Re-add keybind for partially accepting suggestion from zsh-autosuggestions
          bindkey '^[f' forward-word
        '';
    in
      lib.mkMerge [initExtra initExtraBeforeCompInit];

    localVariables = {
      ZVM_INIT_MODE = "sourcing";
    };
  };

  programs.bat.enable = true;
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

  # TODO: add pay-respects later: https://github.com/nix-community/home-manager/issues/6204

  programs.carapace.enable = true;
  programs.carapace.enableZshIntegration = true;

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
      "--long"
      "--no-user"
      "--all"
    ];
  };
}
