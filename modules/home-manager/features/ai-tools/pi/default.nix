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
    lastChangelogVersion = "0.70.2";
    npmCommand = ["bash" "${config.home.homeDirectory}/.pi/agent/scripts/pi-package-npm.sh"];
    packages = [
      "git:github.com/nicobailon/pi-mcp-adapter@v2.5.1"
      "git:github.com/samfoy/pi-lsp-extension@v1.0.0"
      "git:github.com/RimuruW/pi-hashline-edit@v0.6.0"
      "git:github.com/aliou/pi-guardrails@v0.11.0"
      "git:github.com/fluxgear/pi-thinking-steps@v1.0.7"
      "git:github.com/davebcn87/pi-autoresearch@v1.1.0"
      {
        source = "git:github.com/backnotprop/plannotator@0.19.1";
        extensions = ["apps/pi-extension"];
        skills = ["apps/pi-extension/skills"];
      }
    ];
    permissionLevel = "high";
    theme = "github-diff";
  };

  workOverrides = {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-6";
  };

  personalOverrides = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.5";
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
    impeccable.enable = true;
    rtk.enable = true;
    skills = allSkills;
    instructions = commonInstructions;
    settings = piSettings;
  };
}
