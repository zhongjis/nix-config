{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };
}
