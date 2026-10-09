{
  config,
  lib,
  aiProfileHelpers,
  ...
}: {
  programs.pi.settings = lib.mkMerge [
    {
      # UI & Display
      # The Stylix base16 theme comes from ./stylix-theme.nix.
      theme =
        if config.stylix.enable
        then "stylix"
        else "system";
      collapseChangelog = true;
      enableInstallTelemetry = false;
      treeFilterMode = "no-tools";
      editorPaddingX = 0;
      quietStartup = true;
      doubleEscapeAction = "tree";
      defaultProjectTrust = "always";
      tuiMode = "fullscreen";
      fullscreenExitOutput = "resume-hint";

      # Warnings
      warnings.anthropicExtraUsage = false;

      # Compaction
      compaction = {
        enabled = true;
        reserveTokens = 54400;
        keepRecentTokens = 20000;
      };

      # Branch Summary
      branchSummary.skipPrompt = false;

      # Retry
      retry = {
        enabled = true;
        maxRetries = 5;
        baseDelayMs = 2000;
        maxDelayMs = 60000;
      };

      # Message Delivery
      steeringMode = "all";
      followUpMode = "all";
      transport = "auto";
      httpIdleTimeoutMs = 30000;
      websocketConnectTimeoutMs = 10000;

      # Tools
      defaultTools = ["+codemode"];

      npmCommand = ["bash" "${config.home.homeDirectory}/.pi/agent/scripts/pi-package-npm.sh"];

      permissionLevel = "high";
    }
    (lib.mkIf aiProfileHelpers.isWork {
      defaultProvider = "anthropic";
      defaultModel = "claude-opus-4-8";
    })
    # Personal profile:
    # defaultProvider = "llama-swap";
    # defaultModel = "qwen2.5-coder:14b";
  ];
}
