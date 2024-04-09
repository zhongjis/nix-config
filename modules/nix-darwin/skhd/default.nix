{ pkgs, ... }:

{
  services.skhd = {
    enable = true;
    skhdConfig = ''
      ${builtins.readFile ./skhdrc}
      ${builtins.readFile ./yabai-setting}
    '';
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "toggle-float-alacritty" ''
      ${builtins.readFile ./toggle-float-alacritty}
    '')
  ];
}
