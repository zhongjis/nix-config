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
      description = "JSON data symlinked to ~/.pi/agent/settings.json. Immutable — pi cannot override it at runtime.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file =
      mkPathFiles ".pi/agent/skills" cfg.skills
      // {
        ".pi/agent/AGENTS.md".text = instructionsText;
        ".pi/agent/settings.json".source = settingsFile;
      };
  };
}
