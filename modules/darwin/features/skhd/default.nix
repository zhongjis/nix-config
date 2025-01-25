{
  pkgs,
  lib,
  config,
  ...
}: {
  services.skhd = {
    enable = true;
    skhdConfig = ''
      ${builtins.readFile ./yabai-setting}
    '';
  };

  # environment.systemPackages = with pkgs; [
  #   (pkgs.writeScriptBin "toggle-float-alacritty" ''
  #     ${builtins.readFile ./toggle-float-alacritty}
  #   '')
  # ];
}
