{
  inputs,
  pkgs,
  lib,
  commonSkills,
  ompLocalSkills,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  yamlFormat = pkgs.formats.yaml {};
  system = pkgs.stdenv.hostPlatform.system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  allSkills = commonSkills // ompLocalSkills;

  piPlugins = {
    "@sherif-fanous/pi-rtk" = {
      version = "0.3.0";
      versionConstraint = "^0.3.0";
      source = pkgs.fetchzip {
        url = "https://github.com/sherif-fanous/pi-rtk/archive/refs/tags/v0.3.0.tar.gz";
        hash = "sha256-05X2QT4GZI4hWT7u1hWcB4V1IQsrq0OgHBwVVokHNT0=";
      };
    };
  };

  pluginPackageManifest = {
    name = "omp-plugins";
    private = true;
    dependencies = lib.mapAttrs (_: plugin: plugin.versionConstraint) piPlugins;
  };

  pluginLock = {
    plugins =
      lib.mapAttrs (_: plugin: {
        inherit (plugin) version;
        enabledFeatures = null;
        enabled = true;
      })
      piPlugins;
    settings = {};
  };

  # OMP discovers npm plugins from ~/.omp/plugins, so provision the manifest,
  # lock file, and package directory directly instead of requiring imperative
  # `omp plugin install` after every rebuild.
  pluginFiles =
    lib.mapAttrs' (name: plugin: {
      name = ".omp/plugins/node_modules/${name}";
      value = {source = plugin.source;};
    })
    piPlugins;

  sharedConfig = {
    modelRoles = {
      default = "openai-codex/gpt-5.4";
      vision = "openai-codex/gpt-5.4:high";
      smol = "github-copilot/claude-haiku-4.5:off";
      slow = "openai-codex/gpt-5.4:high";
      plan = "github-copilot/claude-opus-4.6:high";
      commit = "github-copilot/claude-haiku-4.5:off";
      task = "openai-codex/gpt-5.4";
    };
  };

  workOverrides = {};

  personalOverrides = {};

  ompConfig = lib.recursiveUpdate sharedConfig (
    if aiProfileHelpers.isWork
    then workOverrides
    else personalOverrides
  );
in {
  imports = [
    ../common/skills
    ../common/instructions
    ./skills
    ./lsp.nix
  ];

  home.packages = [
    llmAgentsPackages.omp
    llmAgentsPackages.rtk
  ];

  home.file =
    lib.mapAttrs' (name: path: {
      name = ".omp/agent/skills/${name}";
      value = {source = path;};
    })
    allSkills
    // pluginFiles
    // {
      ".omp/agent/config.yml".source = yamlFormat.generate "omp-config.yml" ompConfig;
      ".omp/agent/AGENTS.md".text = builtins.concatStringsSep "\n\n" (
        map builtins.readFile commonInstructions
      );
      ".omp/plugins/package.json".source = jsonFormat.generate "omp-plugins-package.json" pluginPackageManifest;
      ".omp/plugins/omp-plugins.lock.json".source = jsonFormat.generate "omp-plugins.lock.json" pluginLock;
    };
}
