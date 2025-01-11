{pkgs, ...}: {
  boot.plymouth = {
    enable = true;
    theme = "catppuccin-mocha";
    themePackages = with pkgs; [
      (catppuccin-plymouth.override {
        variant = "mocha";
      })
    ];
  };
}
