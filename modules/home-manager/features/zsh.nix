{pkgs, ...}: {
  home.file = {
    ".local/share/zsh/zsh-fast-syntax-highlighting".source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    ".local/share/zsh/zsh-autocomplete".source = "${pkgs.zsh-autocomplete}/share/zsh-zshautocomplete";
    ".local/share/zsh/nix-zsh-completions".source = "${pkgs.nix-zsh-completions}/share/zsh/plugins/nix";
    ".local/share/zsh/zsh-vi-mode".source = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    autosuggestion = {
      enable = true;
      highlight = "fg=#ff00ff,bg=cyan,bold,underline";
    };
    dotDir = ".config/zsh";
    history = {
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
    initExtra =
      /*
      bash
      */
      ''
        # PLUGINS (whatever)
        source "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
        source "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
        source "$HOME/.local/share/zsh/nix-zsh-completions/nix.plugin.zsh"
        source "$HOME/.local/share/zsh/zsh-autocompletions/zsh-autocomplete.plugin.zsh"
      '';
  };
}
