{pkgs, ...}: {
  programs.zsh.shellAliases."cht.sh" = "cht";
  home.packages = with pkgs; [
    cht-sh
  ];
}
