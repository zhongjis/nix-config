{
  config,
  lib,
  ...
}: let
  modeType = lib.types.enum [
    "lite"
    "full"
    "ultra"
    "wenyan-lite"
    "wenyan-full"
    "wenyan-ultra"
  ];

  mkCavemanOptions = toolName: {
    enable = lib.mkEnableOption "persistent Caveman mode for ${toolName}";

    mode = lib.mkOption {
      type = modeType;
      default = "full";
      description = "Default Caveman response mode for ${toolName}.";
      example = "ultra";
    };
  };

  opencodeCfg = config.programs.opencode.caveman;
  codexCfg = config.programs.codex.caveman;
  claudeCodeCfg = config.programs."claude-code".caveman;

  modeInstructions = {
    lite = "No filler/hedging. Keep articles + full sentences. Professional but tight.";
    full = "Drop articles, fragments OK, short synonyms. Classic caveman.";
    ultra = "Strip conjunctions only when cause and effect remain unambiguous. One word when enough; state each fact once. No invented prose abbreviations or causal arrows.";
    wenyan-lite = "Semi-classical. Drop filler/hedging but keep grammar structure, classical register.";
    wenyan-full = "Maximum classical terseness. Fully Wenyan/classical Chinese. 80-90% character reduction. Classical sentence patterns, verbs precede objects, subjects often omitted, classical particles.";
    wenyan-ultra = "Extreme abbreviation while keeping classical Chinese feel. Maximum compression, ultra terse.";
  };

  mkInstructionFile = toolName: mode:
    builtins.toFile "${toolName}-caveman-${mode}.md" ''
      Compress conversational replies without losing technical substance or clarity.

      Caveman mode active: ${mode}.
      ${modeInstructions.${mode}}

      Remove filler and pleasantries, not meaning. Preserve not/never/no/only/except, numbers and units, technical names, code, commands, and exact error strings. Keep grammar markers that carry meaning. Never invent prose abbreviations or causal arrows; clarity wins over compression.
      Follow explicit user language requests; otherwise use the user's dominant language. Use Wenyan/classical Chinese only when a wenyan mode is selected, and respect explicit language requests.

      Auto-Clarity: drop caveman for security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread, compression that creates technical ambiguity, or user asks to clarify. Resume caveman after clear part done.
      Boundaries: persisted external prose uses normal language: code, comments, docs, commits, issues, PRs, third-party messages, and memory. Explicit /caveman-compress requests are exempt.
      Persistence: this default remains active until the user changes mode or says /caveman off, "stop caveman", or "normal mode". Off is a conversational override: respond normally for the rest of the session unless the user re-enables caveman; do not remove configuration.
    '';

  opencodeInstructionFile = mkInstructionFile "opencode" opencodeCfg.mode;
  codexInstructionFile = mkInstructionFile "codex" codexCfg.mode;
  claudeCodeInstructionFile = mkInstructionFile "claude-code" claudeCodeCfg.mode;
in {
  options.programs.opencode.caveman = mkCavemanOptions "OpenCode";
  options.programs.codex.caveman = mkCavemanOptions "Codex";
  options.programs."claude-code".caveman = mkCavemanOptions "Claude Code";

  config = lib.mkMerge [
    (lib.mkIf opencodeCfg.enable {
      programs.opencode.settings.instructions = [
        "${opencodeInstructionFile}"
      ];
    })
    (lib.mkIf codexCfg.enable {
      programs.codex.context = lib.mkAfter ''

        ${builtins.readFile codexInstructionFile}
      '';
    })
    (lib.mkIf claudeCodeCfg.enable {
      programs."claude-code".rules."90-caveman" = builtins.readFile claudeCodeInstructionFile;
    })
  ];
}
