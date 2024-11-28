{
  pkgs,
  inputs,
  ...
}: let
in {
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    unzip
  ];

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
