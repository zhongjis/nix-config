{pkgs, ...}: let
  stable_pkgs = with pkgs.stable; [nextcloud-client];
in {
  home.packages = with pkgs;
    [
      # libreoffice
      libreoffice
      hunspell
      hunspellDicts.en_US-large
    ]
    ++ stable_pkgs;
}
