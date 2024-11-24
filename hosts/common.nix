{
  pkgs,
  inputs,
  ...
}: let
in {
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs.unstable; [
    nixd
    unzip
  ];

  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
}
