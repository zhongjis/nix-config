{ lib, config, ... }:

{
  options = {
    yabai.enable = 
      lib.mkEnableOption "enables yabai";
  };

  config = lib.mkIf config.yabai.enable {
    services.yabai = {
      enable = true;
      extraConfig = ''
        ${builtins.readFile ./yabairc}
      '';
    };
  };
}
