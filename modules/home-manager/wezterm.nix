{
  pkgs,
  lib,
  config,
  inputs,
  currentSystem,
  isDarwin,
  ...
}: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };
}
