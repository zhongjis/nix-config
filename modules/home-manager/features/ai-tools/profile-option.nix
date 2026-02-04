{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeManager.aiProfile;
in {
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
  };

  # Export helpers for use in other modules
  _module.args.aiProfileHelpers = {
    profile = cfg;
    isWork = cfg == "work";
    isPersonal = cfg == "personal";
  };
}
