# Factory.ai Module
#
# This module configures Factory.ai by:
# 1. Merging common skills (from ../common/skills) with Factory-specific skills (from ./skills)
# 2. Creating symlinks to skill directories in ~/.factory/skills/
# 3. Assembling ~/.factory/AGENTS.md from common instructions
#
# NOTE: Factory.ai installation is separate and must be done manually or via another mechanism.
# This module only manages the skills and instructions directories.
#
# NOTE: Profile changes require `nh darwin switch .` to take effect.
{
  lib,
  aiProfileHelpers,
  commonSkills,
  factoryLocalSkills,
  commonInstructions,
  ...
}: let
  # Merge pre-filtered common skills and Factory-specific skills
  # Both are already profile-filtered via _module.args
  allSkills = commonSkills // factoryLocalSkills;
in {
  imports = [
    ../common/skills
    ../common/instructions
    ./skills
  ];

  # Create symlinks to all skills in ~/.factory/skills/
  # Each skill directory is symlinked to its nix store path
  home.file =
    lib.mapAttrs' (name: path: {
      name = ".factory/skills/${name}";
      value = {source = path;};
    })
    allSkills
    // {
      # Assemble AGENTS.md from all common instructions
      # Each instruction file is concatenated with double newlines as separator
      ".factory/AGENTS.md".text = builtins.concatStringsSep "\n\n" (
        map builtins.readFile commonInstructions
      );
    };
}
