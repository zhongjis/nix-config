{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi;
  jsonFormat = pkgs.formats.json {};

  mkPathFiles = targetDir: entries:
    lib.mapAttrs' (name: path: {
      name = "${targetDir}/${name}";
      value = {source = path;};
    })
    entries;

  instructionsText = builtins.concatStringsSep "\n\n" (map builtins.readFile cfg.instructions);

  settingsFile = jsonFormat.generate "pi-settings.json" cfg.settings;
in {
  options.programs.pi = {
    enable = lib.mkEnableOption "Pi coding agent";

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = "Skill directories exposed under ~/.pi/agent/skills/.";
    };

    instructions = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Markdown files concatenated into ~/.pi/agent/AGENTS.md.";
    };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = {};
      description = "JSON data written to ~/.pi/agent/settings.json. Copied (not symlinked) so pi can mutate it at runtime.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file =
      mkPathFiles ".pi/agent/skills" cfg.skills
      // {
        ".pi/agent/AGENTS.md".text = instructionsText;
      };

    # Copy settings.json instead of symlinking — pi mutates this file at runtime
    # (e.g., lastChangelogVersion). On each `nh switch`, the file is regenerated
    # from the Nix-declared settings, resetting any runtime mutations.
    home.activation.piSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      install -Dm644 ${settingsFile} ${config.home.homeDirectory}/.pi/agent/settings.json
    '';
  };
}
