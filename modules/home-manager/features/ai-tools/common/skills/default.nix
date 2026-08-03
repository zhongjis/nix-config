{
  inputs,
  pkgs,
  aiProfileHelpers,
  ...
}: {
  _module.args.commonSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
  };

  # Python dependency required by skills with Python helpers.
  home.packages = with pkgs; [
    python312
  ];
}
