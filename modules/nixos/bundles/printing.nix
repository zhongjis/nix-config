{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [];

  environment.systemPackages = with pkgs;
    [
      orca-slicer
      cura-appimage
      freecad-wayland
    ]
    ++ (with pkgs.stable; [
      ]);
}
