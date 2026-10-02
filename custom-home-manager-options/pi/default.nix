{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi;
  types = lib.types;
  jsonFormat = pkgs.formats.json {};

  mkPathFiles = targetDir: entries:
    lib.mapAttrs' (name: path: {
      name = "${targetDir}/${name}";
      value = {source = path;};
    })
    entries;

  piPackage =
    if cfg.opencodeApiKeyFile == null
    then cfg.package
    else
      pkgs.writeShellScriptBin "pi" ''
        if [[ ! -r ${lib.escapeShellArg cfg.opencodeApiKeyFile} ]]; then
          echo "pi: OpenCode API key file not readable: ${cfg.opencodeApiKeyFile}" >&2
          exit 1
        fi

        export OPENCODE_API_KEY="$(<${lib.escapeShellArg cfg.opencodeApiKeyFile})"
        exec ${lib.getExe cfg.package} "$@"
      '';
in {
  options.programs.pi = {
    enable = lib.mkEnableOption "Pi coding agent";

    package = lib.mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Pi package to install when programs.pi.enable is true.";
    };

    opencodeApiKeyFile = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Runtime path to an OpenCode Zen/Go API key file. When set, pi is installed
        through a wrapper that exports OPENCODE_API_KEY without managing auth.json.
      '';
    };

    skills = lib.mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Skill directories exposed under ~/.pi/agent/skills/.";
    };

    extensions = lib.mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Files or directories exposed under ~/.pi/agent/extensions/.";
    };

    context = lib.mkOption {
      type = types.either types.lines types.path;
      default = "";
      description = "Global context written to ~/.pi/agent/AGENTS.md (inline text or a path).";
    };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = {};
      description = "JSON data symlinked to ~/.pi/agent/settings.json. Immutable — pi cannot override it at runtime.";
    };

    models = lib.mkOption {
      type = jsonFormat.type;
      default = {};
      description = "Custom model providers written to ~/.pi/agent/models.json.";
    };

    themes = lib.mkOption {
      type = types.attrsOf jsonFormat.type;
      default = {};
      description = "Pi theme JSON files written to ~/.pi/agent/themes/<name>.json; the name field is set from the attribute name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.opencodeApiKeyFile == null || cfg.package != null;
        message = "programs.pi.package must be set when programs.pi.opencodeApiKeyFile is set.";
      }
    ];

    home.packages = lib.optional (cfg.package != null) piPackage;

    home.file = lib.mkMerge [
      (mkPathFiles ".pi/agent/skills" cfg.skills)
      (mkPathFiles ".pi/agent/extensions" cfg.extensions)
      (lib.mkIf (lib.hm.strings.isPathLike cfg.context) {
        ".pi/agent/AGENTS.md".source = cfg.context;
      })
      (lib.mkIf (!lib.hm.strings.isPathLike cfg.context && cfg.context != "") {
        ".pi/agent/AGENTS.md".text = cfg.context;
      })
      (lib.mkIf (cfg.settings != {}) {
        ".pi/agent/settings.json".source = jsonFormat.generate "pi-settings.json" cfg.settings;
      })
      (lib.mkIf (cfg.models != {}) {
        ".pi/agent/models.json".source = jsonFormat.generate "pi-models.json" cfg.models;
      })
      (lib.mkIf (cfg.themes != {}) (
        lib.mapAttrs' (name: value: {
          name = ".pi/agent/themes/${name}.json";
          value.source = jsonFormat.generate "pi-theme-${name}.json" (value // {inherit name;});
        })
        cfg.themes
      ))
    ];
  };
}
