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
      freecad
    ]
    ++ (with pkgs.stable; [
      ]);
}
