{inputs, ...}: {
  imports = [
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  gtk.enable = true;
  catppuccin.gtk.enable = true;
  catppuccin.gtk.flavor = "mocha";
}
