{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    skhd.enable =
      lib.mkEnableOption "enables skhd";
  };

  config = lib.mkIf config.skhd.enable {
    services.skhd = {
      enable = true;
      skhdConfig = ''
        ${builtins.readFile ./yabai-setting}
      '';
    };

    environment.systemPackages = with pkgs; [
      (pkgs.writeScriptBin "toggle-float-alacritty" ''
        ${builtins.readFile ./toggle-float-alacritty}
      '')
    ];
  };
}
