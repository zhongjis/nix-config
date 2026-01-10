{
  pkgs,
  lib,
  config,
  inputs,
  currentSystem,
  ...
}: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };
}
