{...}: {
  programs.yazi = {
    enable = true;
    catppuccin.enable = true;
    catppuccin.flavor = "mocha";
    enableZshIntegration = true;
  };
}
