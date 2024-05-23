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
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";

      enableZshIntegration = true;
      changeDirWidgetCommand = "fd --type -d";
      changeDirWidgetOptions = [
        "--preview 'tree -C {} | head -200'"
      ];
    };

    home.packages = with pkgs; [
      fd
    ];
  };
}
