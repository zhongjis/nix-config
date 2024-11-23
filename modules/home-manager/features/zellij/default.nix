{...}: {
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;

    catppuccin.enable = true;
    catppuccin.flavor = "mocha";
  };

  xdg.configFile."zellij/config.kdl".source = ./zellij.kdl;
}
