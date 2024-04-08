{ ... }:

{
  services.skhd = {
    enable = true;
    skhdconfig = ''
      ${builtins.readFile ./skhdrc}
      ${builtins.readFile ./yabai-setting}
    '';
  };
}
