{
  config,
  lib,
  inputs ? {},
  ...
}: let
  discoverSkills = profileDir: let
    dirs = builtins.readDir profileDir;
    enabledDirs = lib.filterAttrs (name: type: type == "directory" && !(lib.hasPrefix "disabled-" name)) dirs;
    skills =
      lib.mapAttrs (name: _: profileDir + "/${name}")
      enabledDirs;
  in
    skills;

  fallbackSkillDir = inputs.impeccable + "/.agents/skills";

  resolveSkillDir = toolDir: let
    preferredDir = inputs.impeccable + "/${toolDir}";
  in
    if builtins.pathExists preferredDir
    then preferredDir
    else fallbackSkillDir;

  mkDefaultAttrs = attrs:
    lib.mapAttrs (_: value: lib.mkDefault value) attrs;

  discoverImpeccableSkills = enabled: toolDir:
    if !enabled || !(inputs ? impeccable)
    then {}
    else mkDefaultAttrs (discoverSkills (resolveSkillDir toolDir));

  codexCfg = config.programs.codex.impeccable;
  opencodeCfg = config.programs.opencode.impeccable;
  claudeCodeCfg = config.programs."claude-code".impeccable;
  piCfg = config.programs.pi.impeccable;
  ompCfg = config.programs."oh-my-pi".impeccable;

  impeccableAssertion = optionName: enabled: {
    assertion = !enabled || inputs ? impeccable;
    message = ''
      ${optionName} requires inputs.impeccable.
      If you import this module outside this flake, pass the input explicitly or disable impeccable.
    '';
  };
in {
  options.programs.codex.impeccable.enable =
    lib.mkEnableOption "Impeccable-provided Codex skills";

  options.programs.opencode.impeccable.enable =
    lib.mkEnableOption "Impeccable-provided OpenCode skills";

  options.programs."claude-code".impeccable.enable =
    lib.mkEnableOption "Impeccable-provided Claude Code skills";

  options.programs.pi.impeccable.enable =
    lib.mkEnableOption "Impeccable-provided Pi skills";

  options.programs."oh-my-pi".impeccable.enable =
    lib.mkEnableOption "Impeccable-provided Oh My Pi skills";

  config = lib.mkMerge [
    {
      assertions = [
        (impeccableAssertion "programs.codex.impeccable.enable" codexCfg.enable)
        (impeccableAssertion "programs.opencode.impeccable.enable" opencodeCfg.enable)
        (impeccableAssertion "programs.\"claude-code\".impeccable.enable" claudeCodeCfg.enable)
        (impeccableAssertion "programs.pi.impeccable.enable" piCfg.enable)
        (impeccableAssertion "programs.\"oh-my-pi\".impeccable.enable" ompCfg.enable)
      ];
    }
    (lib.mkIf codexCfg.enable {
      programs.codex.skills = discoverImpeccableSkills true ".codex/skills";
    })
    (lib.mkIf opencodeCfg.enable {
      programs.opencode.skills = discoverImpeccableSkills true ".opencode/skills";
    })
    (lib.mkIf claudeCodeCfg.enable {
      programs."claude-code".skills = discoverImpeccableSkills true ".claude/skills";
    })
    (lib.mkIf piCfg.enable {
      programs.pi.skills = discoverImpeccableSkills true ".pi/skills";
    })
    (lib.mkIf ompCfg.enable {
      programs."oh-my-pi".skills = discoverImpeccableSkills true ".pi/skills";
    })
  ];
}
