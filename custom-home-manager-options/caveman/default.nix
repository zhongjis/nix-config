{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.opencode.caveman;
  modeInstructions = {
    lite = "No filler/hedging. Keep articles + full sentences. Professional but tight.";
    full = "Drop articles, fragments OK, short synonyms. Classic caveman.";
    ultra = "Abbreviate prose words (DB/auth/config/req/res/fn/impl), strip conjunctions, arrows for causality (X -> Y), one word when one word enough. Code symbols, function names, API names, error strings: never abbreviate.";
    wenyan-lite = "Semi-classical. Drop filler/hedging but keep grammar structure, classical register.";
    wenyan-full = "Maximum classical terseness. Fully Wenyan/classical Chinese. 80-90% character reduction. Classical sentence patterns, verbs precede objects, subjects often omitted, classical particles.";
    wenyan-ultra = "Extreme abbreviation while keeping classical Chinese feel. Maximum compression, ultra terse.";
  };
  instructionFile = pkgs.writeText "opencode-caveman-${cfg.mode}.md" ''
    Respond terse like smart caveman. All technical substance stay. Only fluff die.

    Caveman mode active: ${cfg.mode}.
    ${modeInstructions.${cfg.mode}}

    Drop articles, filler, pleasantries, and hedging. Fragments OK. Short synonyms. Technical terms exact. Code blocks unchanged. Errors quoted exact.
    Pattern: [thing] [action] [reason]. [next step].

    Auto-Clarity: drop caveman for security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread, compression that creates technical ambiguity, or user asks to clarify. Resume caveman after clear part done.
    Boundaries: code, commits, and PRs written normal. "stop caveman" or "normal mode" reverts.
  '';
in {
  options.programs.opencode.caveman = {
    enable = lib.mkEnableOption "persistent Caveman mode for OpenCode";

    mode = lib.mkOption {
      type = lib.types.enum [
        "lite"
        "full"
        "ultra"
        "wenyan-lite"
        "wenyan-full"
        "wenyan-ultra"
      ];
      default = "full";
      description = "Default Caveman response mode for OpenCode.";
      example = "ultra";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.opencode.settings.instructions = [
      "${instructionFile}"
    ];
  };
}
