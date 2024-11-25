{pkgs, ...}: let
in {
  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    image = ./gruvbox-mountain-village.png;

    # fonts = {
    #   monospace = {
    #     package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
    #     name = "JetBrainsMono Nerd Font Mono";
    #   };
    #   sansSerif = {
    #     package = pkgs.dejavu_fonts;
    #     name = "DejaVu Sans";
    #   };
    #   serif = {
    #     package = pkgs.dejavu_fonts;
    #     name = "DejaVu Serif";
    #   };

    #   sizes = {
    #     applications = 12;
    #     terminal = 15;
    #     desktop = 10;
    #     popups = 10;
    #   };
    # };

    # cursor.name = "Banana-Gruvbox";
    # cursor.package = pkgs.bibata-cursors;

    # cursor.package = let
    #   banana = pkgs.stdenv.mkDerivation {
    #     name = "banana-cursor";

    #     src = builtins.fetchurl {
    #       url = "https://github.com/vimjoyer/banana-cursor-gruvbox/releases/download/4/Banana-Gruvbox.tar.gz";
    #       sha256 = "sha256-opGDdW7w2eAhwP/fuBES3qA6d7M8I/xhdXiTXoIoGzs=";
    #     };
    #     unpack = false;

    #     installPhase = ''
    #       mkdir -p $out/share/icons/Banana-Gruvbox
    #       tar -xvf $src -C $out/share/icons/Banana-Gruvbox
    #     '';
    #   };
    # in
    #   banana;

    # targets.chromium.enable = true;
    # targets.grub.enable = true;
    # targets.grub.useImage = true;
    # targets.plymouth.enable = true;

    # opacity.terminal = 1;
    # stylix.targets.nixos-icons.enable = true;

    autoEnable = true;
  };
}
