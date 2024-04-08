{ ... }:

{
  services.skhd = {
    enable = true;
    skhdConfig = ''
      ${builtins.readFile ./skhdrc}
      ${builtins.readFile ./yabai-setting}
    '';
  };
}
