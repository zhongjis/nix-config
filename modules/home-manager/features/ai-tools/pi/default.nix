{
  config,
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

  sharedSettings = {
    defaultThinkingLevel = "high";
    quietStartup = true;
    doubleEscapeAction = "tree";
    compaction = {
      enabled = true;
      reserveTokens = 16384;
      keepRecentTokens = 20000;
    };
    retry = {
      enabled = true;
      maxRetries = 3;
      baseDelayMs = 2000;
      maxDelayMs = 60000;
    };
    lastChangelogVersion = "0.66.1";
    npmCommand = ["bash" "${config.home.homeDirectory}/.pi/agent/scripts/pi-package-npm.sh"];
    packages = [
      "git:github.com/nicobailon/pi-mcp-adapter"
      "git:github.com/samfoy/pi-lsp-extension"
      "git:github.com/RimuruW/pi-hashline-edit"
      "git:github.com/aliou/pi-guardrails"
      "git:github.com/lucasmeijer/pi-bash-live-view"
      {
        source = "git:github.com/backnotprop/plannotator";
        extensions = ["git/github.com/backnotprop/plannotator/apps/pi-extension"];
        skills = ["git/github.com/backnotprop/plannotator/apps/pi-extension/skills"];
      }
    ];
    permissionLevel = "high";
  };

  workOverrides = {
    defaultProvider = "anthropic";
    defaultModel = "claude-sonnet-4-6";
  };

  personalOverrides = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.4";
  };

  piSettings = lib.recursiveUpdate sharedSettings (
    if aiProfileHelpers.isWork
    then workOverrides
    else personalOverrides
  );
in {
  imports = [
    ../../../../../custom-home-manager-options/pi
  ];

  home.packages = [llmAgentsPackages.pi];

  programs.pi = {
    enable = true;
    rtk.enable = true;
    skills = allSkills;
    instructions = commonInstructions;
    settings = piSettings;
  };
}
