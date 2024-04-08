{ pkgs, ... }:
{
  programs.zsh.enable = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    (nerdfonts.override { 
        fonts = [ 
         "FiraCode" 
         "DroidSansMono" 
         "Agave"
         "JetBrainsMono"
        ]; 
    })
  ];
}
