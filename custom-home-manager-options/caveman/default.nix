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
    ultra = "Abbreviate prose words (DB/auth/config/req/res/fn/impl), strip conjunctions, arrows for causality (X -> Y), one word when one word enough. Code symbols, function names, API names, error strings: never abbreviate.";
    wenyan-lite = "Semi-classical. Drop filler/hedging but keep grammar structure, classical register.";
    wenyan-full = "Maximum classical terseness. Fully Wenyan/classical Chinese. 80-90% character reduction. Classical sentence patterns, verbs precede objects, subjects often omitted, classical particles.";
    wenyan-ultra = "Extreme abbreviation while keeping classical Chinese feel. Maximum compression, ultra terse.";
  };

  mkInstructionFile = toolName: mode:
    builtins.toFile "${toolName}-caveman-${mode}.md" ''
      Respond terse like smart caveman. All technical substance stay. Only fluff die.

      Caveman mode active: ${mode}.
      ${modeInstructions.${mode}}

      Drop articles, filler, pleasantries, and hedging. Fragments OK. Short synonyms. Technical terms exact. Code blocks unchanged. Errors quoted exact.
      Pattern: [thing] [action] [reason]. [next step].

      Auto-Clarity: drop caveman for security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread, compression that creates technical ambiguity, or user asks to clarify. Resume caveman after clear part done.
      Boundaries: code, commits, and PRs written normal. "stop caveman" or "normal mode" reverts.
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
