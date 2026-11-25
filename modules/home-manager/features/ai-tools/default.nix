{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  profile = config.myHomeManager.aiProfile;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  customModules = import ../../../../custom-home-manager-options;
in {
  imports = [
    customModules.antigravity-cli
    customModules.beads
    customModules.caveman
    customModules.codex
    customModules.icm
    customModules.oh-my-pi
    customModules.pi
    customModules.rtk
    ./profile-option.nix
    ./common
    ./agy
    ./claude-code
    ./codex
    ./copilot
    ./factory
    ./omp
    ./opencode
    ./pi
  ];

  options.myHomeManager.ai-tools = {
    agy.enable = lib.mkEnableOption "Antigravity CLI (agy) configuration";
    claude-code.enable = lib.mkEnableOption "Claude Code configuration";
    codex.enable = lib.mkEnableOption "Codex configuration";
    copilot.enable = lib.mkEnableOption "GitHub Copilot CLI configuration";
    factory.enable = lib.mkEnableOption "Factory.ai configuration";
    omp.enable = lib.mkEnableOption "Oh My Pi configuration";
    opencode.enable = lib.mkEnableOption "OpenCode configuration";
    pi.enable = lib.mkEnableOption "Pi configuration";
  };

  config = {
    myHomeManager.ai-tools = {
      agy.enable = lib.mkDefault (profile == "personal");
      claude-code.enable = lib.mkDefault (profile == "personal");
      codex.enable = lib.mkDefault (profile == "personal");
      copilot.enable = lib.mkDefault (profile == "work");
      pi.enable = lib.mkDefault true;
    };

    programs.beads = {
      enable = true;
      server.enable = true;
    };

    home.packages =
      [
        llmAgentsPackages.qmd
        llmAgentsPackages.codegraph
        # llmAgentsPackages.agentsview
        llmAgentsPackages.skills
        llmAgentsPackages.agent-browser
        llmAgentsPackages.open-code-review
        inputs.self.packages.${system}.before-and-after

        # for before-and-after skill
        pkgs.imagemagick
        pkgs.ffmpeg
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # llmAgentsPackages.t3code-desktop
        # llmAgentsPackages.chatgpt
      ];
  };
}
