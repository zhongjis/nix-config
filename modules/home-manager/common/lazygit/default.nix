{ pkgs, lib, config, ... }:

{
  options = {
    lazygit.enable =
      lib.mkEnableOption "enables lazygit";
  };

  config = lib.mkIf config.lazygit.enable {
    programs.lazygit = {
      enable = true;
      settings = {
        gui = {
          # NOTE: https://github.com/catppuccin/lazygit/tree/main
          theme = {
            activeBorderColor = [ "#89b4fa" "bold" ];
            inactiveBorderColor = [ "#a6adc8" ];
            optionsTextColor = [ "#89b4fa" ];
            selectedLineBgColor = [ "#313244" ];
            cherryPickedCommitBgColor = [ "#45475a" ];
            cherryPickedCommitFgColor = [ "#89b4fa" ];
            unstagedChangesColor = [ "#f38ba8" ];
            defaultFgColor = [ "#cdd6f4" ];
            searchingActiveBorderColor = [ "#f9e2af" ];
          };
          authorColor = {
            "*" = "'#b4befe";
          };
        };
      };
    };
  };
}
