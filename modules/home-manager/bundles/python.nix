{pkgs, ...}: let
  stable_pkgs = with pkgs; [];
in {
  home.packages = with pkgs;
    [
      python312
      python312Packages.uv
      basedpyright
    ]
    ++ stable_pkgs;
}
