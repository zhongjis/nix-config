{
  inputs,
  lib,
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

  impeccableFactorySkills = discoverSkills (inputs.impeccable + "/.agents/skills");
in {
  _module.args = {inherit impeccableFactorySkills;};
}
