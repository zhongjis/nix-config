{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    fzf.enable =
      lib.mkEnableOption "enables fzf";
  };

  config = lib.mkIf config.fzf.enable {
    programs.fzf = {
      enable = true;

      enableZshIntegration = true;
      changeDirWidgetCommand = "fd --type -d";
      changeDirWidgetOptions = [
        "--preview 'tree -C {} | head -200'"
      ];
      # https://github.com/catppuccin/fzf/issues/9
      colors = {
        "bg+" = "#313244";
        spinner = "#f5e0dc";
        hl = "#f38ba8";
        fg = "#cdd6f4";
        header = "#f38ba8";
        info = "#cba6f7";
        pointer = "#f5e0dc";
        marker = "#f5e0dc";
        "fg+" = "#cdd6f4";
        prompt = "#cba6f7";
        "hl+" = "#f38ba8";
      };
    };

    home.packages = with pkgs; [
      fd
    ];
  };
}
