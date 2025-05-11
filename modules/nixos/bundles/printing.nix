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
    ]
    ++ (with pkgs.stable; [
      ]);
}
