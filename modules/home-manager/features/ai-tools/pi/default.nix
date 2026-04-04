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
  system = pkgs.stdenv.hostPlatform.system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  allSkills = commonSkills // ompLocalSkills;

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
    ../../../../../custom-home-manager-options/oh-my-pi
    ./skills
    ./lsp.nix
  ];

  programs."oh-my-pi" = {
    enable = true;
    package = llmAgentsPackages.omp;

    impeccable.enable = true;

    settings = ompConfig;
    # models = {};
    skills = allSkills;
    commands = {};
    rules = {};
    agents = {};
    instructions = commonInstructions;

    rtk.enable = true;
  };
}
