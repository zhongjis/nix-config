# Factory.ai Module
#
# This module configures Factory.ai by:
# 1. Creating symlinks to catalog-selected skill directories in ~/.factory/skills/
# 2. Assembling ~/.factory/AGENTS.md from common instructions
#
# NOTE: Factory.ai installation is separate and must be done manually or via another mechanism.
# This module only manages the skills and instructions directories.
#
# NOTE: Profile changes require `nh darwin switch .` to take effect.
{
  inputs,
  lib,
  aiProfileHelpers,
  commonInstructions,
  ...
}: let
  catalogSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
    harness = "factory";
  };
in {
  imports = [
    ../common/instructions
  ];

  # Create symlinks to all skills in ~/.factory/skills/
  # Each skill directory is symlinked to its nix store path
  home.file =
    lib.mapAttrs' (name: path: {
      name = ".factory/skills/${name}";
      value = {source = path;};
    })
    catalogSkills
    // {
      # Assemble AGENTS.md from all common instructions
      # Each instruction file is concatenated with double newlines as separator
      ".factory/AGENTS.md".text = builtins.concatStringsSep "\n\n" (
        map builtins.readFile commonInstructions
      );
    };
}
