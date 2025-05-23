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
    ]
    ++ (with pkgs.stable; [
      ]);
}
