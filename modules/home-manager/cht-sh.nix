{pkgs, ...}: {
  programs.zsh.shellAliases."cht" = "cht.sh";
  home.packages = with pkgs; [
    cht-sh
  ];
}
