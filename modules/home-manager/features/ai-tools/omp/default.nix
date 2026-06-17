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
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  allSkills = commonSkills // ompLocalSkills;

  sharedConfig = {
    providers.webSearch = "auto";
    symbolPreset = "unicode";
    theme.dark = "titanium";
    setupVersion = 1;

    modelRoles = {
      default = "openai-codex/gpt-5.5:xhigh";
      vision = "openai-codex/gpt-5.5:high";
      smol = "github-copilot/claude-haiku-4.5:off";
      slow = "openai-codex/gpt-5.5:xhigh";
      plan = "github-copilot/claude-opus-4.8:xhigh";
      commit = "github-copilot/claude-haiku-4.5:off";
      task = "openai-codex/gpt-5.5:xhigh";
    };
  };

  workOverrides = {
    # Anthropic ULW (ultra-large-window, 1M context) models
    modelRoles = {
      default = "anthropic/claude-opus-4-8:xhigh";
      vision = "github-copilot/gpt-5.5:high";
      smol = "anthropic/claude-haiku-4-5:off";
      slow = "anthropic/claude-opus-4-8:xhigh";
      plan = "anthropic/claude-opus-4-8:xhigh";
      commit = "anthropic/claude-haiku-4-5:off";
      task = "anthropic/claude-sonnet-4-6:xhigh";
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
