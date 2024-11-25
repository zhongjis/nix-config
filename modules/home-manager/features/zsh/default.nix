{
  pkgs,
  currentSystemName,
  ...
}: let
  oswitchCMD = "nh os switch . --hostname ${currentSystemName}";
  otestCMD = "nh os test . --hostname ${currentSystemName}";
  hswitchCMD =
    if currentSystemName == "mac-m1-max"
    then "nh home switch . -c zshen-mac"
    else "nh home switch . -c zshen-linux";
  htestCMD =
    if currentSystemName == "mac-m1-max"
    then "nh home test . -c zshen-mac"
    else "nh home test . -c zshen-linux";
in {
  home.file = {
    ".local/share/zsh/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    ".local/share/zsh/zsh-fast-syntax-highlighting".source = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
    ".local/share/zsh/nix-zsh-completions".source = "${pkgs.nix-zsh-completions}/share/zsh/plugins/nix";
    ".local/share/zsh/zsh-vi-mode".source = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
  };

  programs.zsh = {
    enable = true;
    # enableCompletion = true;
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

      oswitch = oswitchCMD;
      otest = otestCMD;
      hswitch = hswitchCMD;
      htest = htestCMD;
    };
    initExtra =
      /*
      bash
      */
      ''
        # PLUGINS (whatever)
        [ -f "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ] && \
        source "$HOME/.local/share/zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

        [ -f "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ] && \
        source "$HOME/.local/share/zsh/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"
        bindkey '^ ' autosuggest-accept

        [ -f "$HOME/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
        source "$HOME/.local/share/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

        [ -f "$HOME/.local/share/zsh/nix-zsh-completions/nix.plugin.zsh" ] && \
        source "$HOME/.local/share/zsh/nix-zsh-completions/nix.plugin.zsh"
      '';
  };
}
