{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  cfg = config.programs."oh-my-pi";
  types = lib.types;
  jsonFormat = pkgs.formats.json {};
  yamlFormat = pkgs.formats.yaml {};
  system = pkgs.stdenv.hostPlatform.system;

  defaultOmpPackage =
    if inputs ? llm-agents
    then inputs.llm-agents.packages.${system}.omp
    else null;

  pluginType = types.submodule ({...}: {
    options = {
      version = lib.mkOption {
        type = types.str;
        description = "Resolved plugin version recorded in omp-plugins.lock.json.";
      };

      versionConstraint = lib.mkOption {
        type = types.str;
        description = "Dependency constraint written to ~/.omp/plugins/package.json.";
      };

      source = lib.mkOption {
        type = types.path;
        description = "Plugin source tree to expose under ~/.omp/plugins/node_modules/<name>.";
      };
    };
  });

  effectivePlugins = cfg.plugins;

  effectiveExtensions = cfg.extensions;

  pluginPackageManifest = {
    name = "omp-plugins";
    private = true;
    dependencies = lib.mapAttrs (_: plugin: plugin.versionConstraint) effectivePlugins;
  };

  pluginLock = {
    plugins =
      lib.mapAttrs (_: plugin: {
        inherit (plugin) version;
        enabledFeatures = null;
        enabled = true;
      })
      effectivePlugins;
    settings = {};
  };

  instructionsText = builtins.concatStringsSep "\n\n" (map builtins.readFile cfg.instructions);

  mkPathFiles = targetDir: entries:
    lib.mapAttrs' (name: path: {
      name = "${targetDir}/${name}";
      value = {source = path;};
    })
    entries;

  mkMarkdownFiles = targetDir: entries:
    lib.mapAttrs' (name: path: {
      name = "${targetDir}/${name}.md";
      value = {source = path;};
    })
    entries;

  mkPluginFiles = lib.mapAttrs' (name: plugin: {
    name = ".omp/plugins/node_modules/${name}";
    value = {source = plugin.source;};
  });

  markdownNameAssertion = optionName: entries: let
    invalidNames = lib.filter (name: lib.hasSuffix ".md" name) (builtins.attrNames entries);
  in {
    assertion = invalidNames == [];
    message = ''
      programs."oh-my-pi".${optionName} keys must omit the .md suffix.
      Invalid keys: ${lib.concatStringsSep ", " invalidNames}
    '';
  };
in {
  options.programs."oh-my-pi" = {
    enable = lib.mkEnableOption "Oh My Pi";

    package = lib.mkOption {
      type = types.nullOr types.package;
      default = defaultOmpPackage;
      defaultText = lib.literalExpression "inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp";
      description = "Oh My Pi package to install when the module is enabled.";
    };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = {};
      description = "YAML data written to ~/.omp/agent/config.yml.";
    };

    models = lib.mkOption {
      type = types.nullOr yamlFormat.type;
      default = null;
      description = "Optional YAML data written to ~/.omp/agent/models.yml when custom providers/models are configured.";
    };

    skills = lib.mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Skill directories exposed under ~/.omp/agent/skills/.";
    };

    commands = lib.mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Markdown command files written to ~/.omp/agent/commands/<name>.md.";
    };

    rules = lib.mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Markdown rule files written to ~/.omp/agent/rules/<name>.md.";
    };

    agents = lib.mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Markdown agent files written to ~/.omp/agent/agents/<name>.md.";
    };

    instructions = lib.mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Markdown files concatenated into ~/.omp/agent/AGENTS.md.";
    };

    extensions = lib.mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Files or directories exposed under ~/.omp/agent/extensions/.";
    };

    impeccable = {
      enable = lib.mkEnableOption "Impeccable-provided Oh My Pi skills";
    };

    plugins = lib.mkOption {
      type = types.attrsOf pluginType;
      default = {};
      description = ''
        Declarative Oh My Pi plugins keyed by package name.
        Each entry is linked into ~/.omp/plugins/node_modules and recorded in the plugin manifest and lock file.
      '';
    };

    lsp = lib.mkOption {
      type = yamlFormat.type;
      default = {};
      description = "YAML data written to ~/.omp/agent/lsp.yaml.";
    };

  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || cfg.package != null;
          message = ''
            programs."oh-my-pi".package must be set when programs."oh-my-pi".enable is true.
            If you import this module outside this flake, pass the package explicitly or provide inputs.llm-agents.
          '';
        }
        {
          assertion = !cfg.impeccable.enable || inputs ? impeccable;
          message = ''
            programs."oh-my-pi".impeccable.enable requires inputs.impeccable.
            If you import this module outside this flake, pass the input explicitly or disable impeccable.
          '';
        }
        (markdownNameAssertion "commands" cfg.commands)
        (markdownNameAssertion "rules" cfg.rules)
        (markdownNameAssertion "agents" cfg.agents)
      ];
    }
    (lib.mkIf cfg.enable {
      home.packages = [cfg.package];

      home.file =
        mkPathFiles ".omp/agent/skills" cfg.skills
        // mkPathFiles ".omp/agent/extensions" effectiveExtensions
        // mkMarkdownFiles ".omp/agent/commands" cfg.commands
        // mkMarkdownFiles ".omp/agent/rules" cfg.rules
        // mkMarkdownFiles ".omp/agent/agents" cfg.agents
        // mkPluginFiles effectivePlugins
        // {
          ".omp/agent/config.yml".source = yamlFormat.generate "omp-config.yml" cfg.settings;
          ".omp/agent/AGENTS.md".text = instructionsText;
          ".omp/agent/lsp.yaml".source = yamlFormat.generate "omp-lsp.yaml" cfg.lsp;
          ".omp/plugins/package.json".source = jsonFormat.generate "omp-plugins-package.json" pluginPackageManifest;
          ".omp/plugins/omp-plugins.lock.json".source = jsonFormat.generate "omp-plugins.lock.json" pluginLock;
        }
        // lib.optionalAttrs (cfg.models != null) {
          ".omp/agent/models.yml".source = yamlFormat.generate "omp-models.yml" cfg.models;
        };
    })
  ];
}
