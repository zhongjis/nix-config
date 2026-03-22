{
  inputs,
  pkgs,
  lib,
  commonSkills,
  piLocalSkills,
  commonInstructions,
  aiProfileHelpers,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};
  system = pkgs.stdenv.hostPlatform.system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  allSkills = commonSkills // piLocalSkills;

  sharedConfig = {
    modelRoles = {
      default = "openai-codex/gpt-5.4:high";
      vision = "openai-codex/gpt-5.3-codex:low";
      smol = "github-copilot/claude-haiku-4.5:off";
      slow = "openai-codex/gpt-5.4:high";
      plan = "openai-codex/gpt-5.4:high";
      commit = "github-copilot/claude-haiku-4.5:high";
      task = "openai-codex/gpt-5.4:high";
    };
  };

  workOverrides = {
    modelRoles = {
      task = "github-copilot/claude-sonnet-4.6";
      vision = "openai/gpt-5.3-codex";
    };
  };

  personalOverrides = {};

  piConfig = lib.recursiveUpdate sharedConfig (
    if aiProfileHelpers.isWork
    then workOverrides
    else personalOverrides
  );
in {
  imports = [
    ../common/skills
    ../common/instructions
    ./skills
  ];

  home.packages = [
    llmAgentsPackages.pi
    llmAgentsPackages.omp
  ];

  home.file =
    lib.mapAttrs' (name: path: {
      name = ".omp/agent/skills/${name}";
      value = {source = path;};
    })
    allSkills
    // lib.mapAttrs' (name: path: {
      name = ".pi/skills/${name}";
      value = {source = path;};
    })
    allSkills
    // {
      ".omp/agent/commands".source = inputs.oh-my-pi + "/.omp/commands";
      ".omp/agent/rules".source = inputs.oh-my-pi + "/.omp/rules";
      ".omp/agent/config.yml".source = yamlFormat.generate "pi-config.yml" piConfig;
      ".omp/agent/AGENTS.md".text = builtins.concatStringsSep "\n\n" (
        map builtins.readFile commonInstructions
      );
    };
}
