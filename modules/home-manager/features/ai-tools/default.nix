{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.myHomeManager.aiProfile;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
in {
  imports = [
    ../../../../custom-home-manager-options/impeccable
    ../../../../custom-home-manager-options/rtk
    ./common
    ./codex
    ./opencode
    ./claude-code
    ./factory
    ./omp
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

    home.packages =
      [llmAgentsPackages.gitnexus]
      ++ lib.optional (inputs.self.packages.${system} ? sentrux)
      inputs.self.packages.${system}.sentrux;
  };
}
