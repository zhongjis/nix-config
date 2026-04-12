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

  workOverrides = {
    # Anthropic ULW (ultra-large-window, 1M context) models
    modelRoles = {
      default = "anthropic/claude-sonnet-4-6";
      vision = "github-copilot/gpt-5.4:high";
      smol = "anthropic/claude-haiku-4-5:off";
      slow = "anthropic/claude-opus-4-6:high";
      plan = "anthropic/claude-opus-4-6:high";
      commit = "anthropic/claude-haiku-4-5:off";
      task = "anthropic/claude-sonnet-4-6";
    };
  };

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
    skills = allSkills;
    instructions = commonInstructions;

    rtk.enable = true;

    # models = {};
    # extensions = {
    #   # The upstream direnv extension imports shared helpers from ../_shared.
    #   _shared = piAgentKitExtensions + "/_shared";
    #   direnv = piAgentKitExtensions + "/direnv";
    #   "ultrawork.ts" = ./extensions/ultrawork.ts;
    #   "plan.ts" = ./extensions/plan.ts;
    # };
    # commands = {};
    # rules = {
    #   sisyphus-protocol = ./rules/sisyphus-protocol.md;
    # };
    # agents = {
    #   prometheus = ./agents/prometheus.md;
    #   metis = ./agents/metis.md;
    #   momus = ./agents/momus.md;
    # };
  };
}
