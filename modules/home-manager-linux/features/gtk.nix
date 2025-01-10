{
  lib,
  pkgs,
  ...
}: {
  gtk.enable = true;
  gtk.iconTheme.name = "Dracula";
  gtk.iconTheme.package = pkgs.dracula-icon-theme;
  gtk.theme.name = lib.mkForce "Dracula";
  gtk.theme.package = lib.mkForce pkgs.dracula-theme;
}
