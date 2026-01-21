{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports =
    [
      ../../modules/home-manager
    ]
    ++ inputs.nix-config-private.homeModules.zshen-nix-config-private;

  zshen-private-flake.adobe-marketo-flex.enable = true;

  myHomeManager.bundles.general.enable = true;
  myHomeManager.bundles.darwin.enable = true;

  home.username = "zshen";
  home.homeDirectory = lib.mkForce "/Users/zshen";
  home.stateVersion = "23.11"; # Please read the comment before changing.
  home.packages = with pkgs; [];
  home.file = {};
}
