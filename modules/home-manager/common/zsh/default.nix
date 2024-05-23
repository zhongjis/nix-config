{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    zsh.enable =
      lib.mkEnableOption "enables zsh";
  };

  config = lib.mkIf config.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      dotDir = ".config/zsh";
      autosuggestion = {
        enable = true;
        highlight = "fg=#ff00ff,bg=cyan,bold,underline";
      };
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "gh"
          "terraform"
          "vi-mode"
          "autojump"
          "sublime-merge"
          "mvn"
          "kubectl"
        ];
      };
      history = {
        expireDuplicatesFirst = true;
        extended = true;
        save = 10000;
        size = 10000;
      };
      shellAliases = {
        cat = "bat";
        nixswitch = "sudo nixos-rebuild switch --flake ~/nix-config/#thinkpad-t480 --show-trace";
        nixtest = "sudo nixos-rebuild test --flake ~/nix-config/#thinkpad-t480 --show-trace";
        darwinswitch = "darwin-rebuild switch --flake .#mac-m1-max --show-trace";
      };
      initExtra = ''
        ${builtins.readFile ./catppuccin_mocha-zsh-syntax-highlighting.zsh}
      '';
    };

    programs.starship = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      enableZshIntegration = true;

      settings = {
        aws = {
          disabled = true;
        };
        kubernetes = {
          disabled = false;
          format = "[⛵ $context \($namespace\)](dimmed green) \n";
          detect_folders = ["inventories" "templates"];
        };
      };
    };

    programs.bat = {
      enable = true;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = true;
      extraOptions = [
        "--group-directories-first"
        "--long"
        "--no-user"
      ];
    };

    home.packages = with pkgs; [
      autojump
    ];
  };
}
