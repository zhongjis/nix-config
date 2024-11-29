{
  pkgs,
  config,
  currentSystemName,
  ...
}: {
  home.file = {
    ".local/share/zsh/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    ".local/share/zsh/zsh-fast-syntax-highlighting".source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    ".local/share/zsh/zsh-fzf-tab".source = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
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
        source "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
        # source "$HOME/.local/share/zsh/zsh-fzf-tab/fzf-tab.plugin.zsh"
        source "$HOME/.local/share/zsh/zsh-fzf-tab/fzf-tab.plugin.zsh"

        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#${config.lib.stylix.colors.base03},bg=cyan,bold,underline"
        source "$HOME/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
      '';
  };

  home.packages = with pkgs; [
    bat
    # carapace
    # zoxide
  ];

  programs.eza = {
    enable = true;
    enableZshIntegration = false;
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
