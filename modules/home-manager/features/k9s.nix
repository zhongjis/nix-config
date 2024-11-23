{...}: {
  programs.k9s = {
    enable = true;
    catppuccin.enable = true;
    catppuccin.flavor = "mocha";

    settings = {
      k9s = {
        refreshRate = 2;
      };
    };
  };
}
