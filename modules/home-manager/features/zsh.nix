{
  pkgs,
  config,
  ...
}: {
  home.file = {
    ".local/share/zsh/zsh-fast-syntax-highlighting".source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    ".local/share/zsh/zsh-vi-mode".source = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
    ".local/share/zsh/zsh-autocomple".source = "${pkgs.unstable.zsh-autocomplete}/share/zsh-autocomplete";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#${config.lib.stylix.colors.base03},bg=cyan,bold,underline";
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
    initExtra = ''
      # PLUGINS (whatever)
      source "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

      # The plugin will auto execute this zvm_after_init function
      function zvm_after_init() {
        source "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
        # source "$HOME/.local/share/zsh/zsh-autocomple/zsh-autocomplete.plugin.zsh"

        # Enable fzf zsh integration
        if [[ $options[zle] = on ]]; then
          eval "$(${pkgs.fzf}/bin/fzf --zsh)"
        fi
      }

      # The plugin will auto execute this zvm_after_lazy_keybindings function
      function zvm_after_lazy_keybindings() {
        # # zsh-autocomplete Make Tab and ShiftTab change the selection in the menu
        # bindkey -M menuselect              '^I'         menu-complete
        # bindkey -M menuselect "$terminfo[kcbt]" reverse-menu-complete
        # # zsh-autocomplete Make Enter always submit the command line
        # bindkey -M menuselect '^M' .accept-line
      }
    '';
  };
}
