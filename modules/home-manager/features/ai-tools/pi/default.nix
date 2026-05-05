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

  convertEnvPlaceholders = value:
    if builtins.isString value
    then let
      match = builtins.match "[{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" value;
    in
      if match != null
      then "$env:${builtins.elemAt match 0}"
      else value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: convertEnvPlaceholders) value
    else if builtins.isList value
    then map convertEnvPlaceholders value
    else value;

  normalizeMcporterServer = server: let
    converted = convertEnvPlaceholders server;
  in
    if converted ? url && !(converted ? baseUrl)
    then builtins.removeAttrs (converted // {baseUrl = converted.url;}) ["url"]
    else converted;

  mcporterConfig = {
    "$schema" = "https://raw.githubusercontent.com/steipete/mcporter/main/mcporter.schema.json";
    imports = [];
    mcpServers = lib.mapAttrs (_: normalizeMcporterServer) config.programs.mcp.servers;
  };

  piMcporterSettings = {
    configPath = "${config.home.homeDirectory}/.mcporter/mcporter.json";
    timeoutMs = 30000;
    mode = "lazy";
  };

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
    lastChangelogVersion = "0.73.0";
    collapseChangelog = true;
    treeFilterMode = "no-tools";
    # Only read by openai-codex provider; ignored by others (no fallback).
    # Options: "sse" (default), "websocket", "websocket-cached", "auto".
    # "websocket-cached" = WS + cached prompt context, no SSE fallback on failure.
    transport = "websocket-cached";
    npmCommand = ["bash" "${config.home.homeDirectory}/.pi/agent/scripts/pi-package-npm.sh"];
    packages = [
      "git:github.com/mavam/pi-mcporter@v0.3.1"
      "git:github.com/RimuruW/pi-hashline-edit@v0.6.0"
      "git:github.com/aliou/pi-guardrails@v0.11.0"
      "git:github.com/fluxgear/pi-thinking-steps@v1.0.8"
      "git:github.com/Gurpartap/pi-mermaid@v0.3.0"
      "git:github.com/davebcn87/pi-autoresearch@v1.2.0"
      {
        source = "git:github.com/backnotprop/plannotator@0.19.1";
        extensions = ["apps/pi-extension"];
        skills = ["apps/pi-extension/skills"];
      }
    ];
    permissionLevel = "high";
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

  home.packages = [
    llmAgentsPackages.pi
    llmAgentsPackages.mcporter
  ];

  home.file = {
    ".mcporter/mcporter.json".text = builtins.toJSON mcporterConfig;
    ".pi/agent/mcporter.json".text = builtins.toJSON piMcporterSettings;
  };

  programs.pi = {
    enable = true;
    impeccable.enable = true;
    rtk.enable = true;
    skills = allSkills;
    instructions =
      commonInstructions
      ++ [
        "${./instructions/shell-tools.md}"
      ];
    settings = piSettings;
  };
}
