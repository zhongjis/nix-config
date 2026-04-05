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
  piAgentKitExtensions =
    (pkgs.fetchFromGitHub {
      owner = "aldoborrero";
      repo = "pi-agent-kit";
      rev = "a307560a447da0efc8cdfa672e49ca5ae4aa554d";
      hash = "sha256-aYikbALMzZZLQADNPAsr77qk2762iH4w5x3laII8obA=";
    })
    + "/extensions";
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
    extensions = {
      # The upstream direnv extension imports shared helpers from ../_shared.
      _shared = piAgentKitExtensions + "/_shared";
      direnv = piAgentKitExtensions + "/direnv";
      "ultrawork.ts" = ./extensions/ultrawork.ts;
    };
    commands = {
      plan-prometheus = ./commands/plan-prometheus.md;
    };
    rules = {
      sisyphus-protocol = ./rules/sisyphus-protocol.md;
    };
    agents = {
      prometheus = ./agents/prometheus.md;
      metis = ./agents/metis.md;
      momus = ./agents/momus.md;
    };
    instructions = commonInstructions;

    rtk.enable = true;
  };
}
