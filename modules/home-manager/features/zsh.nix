{
  pkgs,
  config,
  currentSystemName,
  ...
}: {
  home.file = {
    ".local/share/zsh/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    ".local/share/zsh/zsh-fast-syntax-highlighting".source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    ".local/share/zsh/zsh-vi-mode".source = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
    # ".local/share/zsh/zsh-fzf-tab".source = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
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

      otest = "nh os test --hostname ${currentSystemName}";
      oswitch = "nh os switch --hostname ${currentSystemName}";
      oboot = "nh os boot --hostname ${currentSystemName}";
      hswitch = "nh home switch -c ${currentSystemName}";
    };
    initExtra =
      /*
      bash
      */
      ''
        source "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

        source "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#${config.lib.stylix.colors.base03},bg=cyan,bold,underline"
        source "$HOME/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

        export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
        zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
        source <(carapace _carapace)

        function zvm_after_lazy_keybindings() {
          # In normal mode, press Ctrl-R to invoke this widget
          bindkey '^R' fzf-history-widget
        }
      '';
  };

  home.packages = with pkgs; [
    bat
    carapace
    # zoxide
  ];

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
