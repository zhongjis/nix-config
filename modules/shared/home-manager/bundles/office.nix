{pkgs, ...}: {
  home.packages = with pkgs; [
    nextcloud-client
    # libreoffice
    libreoffice
    hunspell
    hunspellDicts.en_US-large
  ];
}
