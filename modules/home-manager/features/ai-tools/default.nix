{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.myHomeManager.aiProfile;
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
    customModules.rtk
    ./common
    ./agy
    ./codex
    # ./opencode
    ./claude-code
    # ./factory
    # ./omp
    ./pi
  ];

  options.myHomeManager.aiProfile = lib.mkOption {
    type = lib.types.enum ["work" "personal"];
    description = "AI tools profile: 'work' for work-specific configuration, 'personal' for personal use";
    example = "work";
  };

  config = {
    assertions = [
      {
        assertion = !config.myHomeManager.ai-tools.enable || cfg != null;
        message = "myHomeManager.aiProfile must be set when myHomeManager.ai-tools is enabled";
      }
    ];

    # Export helpers via config attribute
    _module.args.aiProfileHelpers = {
      profile = cfg;
      isWork = cfg == "work";
      isPersonal = cfg == "personal";
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
