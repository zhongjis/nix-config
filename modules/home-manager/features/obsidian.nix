{
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
in {
  home.packages = [
    llmAgentsPackages.qmd
  ];
  # NOTE: package managed outside Home Manager (NixOS system packages / Homebrew cask)
  programs.obsidian = {
    enable = true;
    package = null;
    cli.enable = true;
  };
}
