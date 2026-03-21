{
  inputs,
  lib,
  aiProfileHelpers,
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

  ohMyPiSkills = discoverSkills (inputs.oh-my-pi + "/.omp/skills");
  localGeneralSkills = discoverSkills ./general;
  localWorkSkills = discoverSkills ./work;
  localPersonalSkills = discoverSkills ./personal;

  filteredLocalSkills =
    localGeneralSkills
    // lib.optionalAttrs aiProfileHelpers.isWork localWorkSkills
    // lib.optionalAttrs aiProfileHelpers.isPersonal localPersonalSkills;
in {
  _module.args.piLocalSkills = ohMyPiSkills // filteredLocalSkills;
}
