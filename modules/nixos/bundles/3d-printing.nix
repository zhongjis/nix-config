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
      freecad-wayland
    ]
    ++ (with pkgs.stable; [
      ]);
}
