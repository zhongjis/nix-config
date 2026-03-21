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
      smol = "github-copilot/gemini-3-flash-preview";
      slow = "openai/gpt-5.4";
      plan = "openai/gpt-5.4";
    };
  };

  workOverrides = {};

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
    // {
      ".omp/agent/commands".source = inputs.oh-my-pi + "/.omp/commands";
      ".omp/agent/rules".source = inputs.oh-my-pi + "/.omp/rules";
      ".omp/agent/config.yml".source = yamlFormat.generate "pi-config.yml" piConfig;
      ".omp/agent/AGENTS.md".text = builtins.concatStringsSep "\n\n" (
        map builtins.readFile commonInstructions
      );
    };
}
