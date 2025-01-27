{pkgs, ...}: {
  home.packages = with pkgs; [
    # libreoffice
    libreoffice
    hunspell
    hunspellDicts.en_US-large

    # pdf reader
    okular
  ];
}
