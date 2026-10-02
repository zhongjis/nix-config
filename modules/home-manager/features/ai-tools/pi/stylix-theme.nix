{
  config,
  lib,
  ...
}:
lib.mkIf config.stylix.enable (let
  colors = config.lib.stylix.colors;
  slots = map (i: "base0${lib.toHexString i}") (lib.range 0 15);
  vars = lib.genAttrs slots (slot: colors.withHashtag.${slot});
  # The editor border stays one color at every thinking level.
  editorBorder = "base0D";

  defaultRoles = {
    accent = "base0D";
    border = "base04";
    borderAccent = "base0D";
    borderMuted = "base03";
    success = "base0B";
    error = "base08";
    warning = "base0A";
    text = "base05";
    muted = "base04";
    dim = "base03";
    thinkingText = "base04";
    selectedBg = "base02";
    userMessageBg = "base01";
    userMessageText = "base05";
    customMessageBg = "base01";
    customMessageText = "base04";
    customMessageLabel = "base0E";
    toolPendingBg = "base01";
    toolTitle = "base05";
    toolOutput = "base04";
    mdHeading = "base0D";
    mdLink = "base08";
    mdLinkUrl = "base09";
    mdCode = "base0B";
    mdCodeBlock = "base0B";
    mdCodeBlockBorder = "base03";
    mdQuote = "base0C";
    mdQuoteBorder = "base03";
    mdHr = "base03";
    mdListBullet = "base08";
    toolDiffAdded = "base0B";
    toolDiffRemoved = "base08";
    toolDiffContext = "base04";
    syntaxComment = "base03";
    syntaxKeyword = "base0E";
    syntaxFunction = "base0D";
    syntaxVariable = "base08";
    syntaxString = "base0B";
    syntaxNumber = "base09";
    syntaxType = "base0A";
    syntaxOperator = "base05";
    syntaxPunctuation = "base05";
    thinkingOff = editorBorder;
    thinkingMinimal = editorBorder;
    thinkingLow = editorBorder;
    thinkingMedium = editorBorder;
    thinkingHigh = editorBorder;
    thinkingXhigh = editorBorder;
    thinkingMax = editorBorder;
    bashMode = "base0B";
    scrollbarTrack = "base03";
    scrollbarThumb = "base05";
    searchMatchBg = "base02";
    searchMatchText = "base0A";
  };

  # tokyo-night-dark bends base16 (base08 is off-white, base0A is cyan, no yellow/orange, base01 is darker than base00, base09 equals base05, and base04 is under 3:1 contrast on base02 panels).
  tokyoNightDarkOverrides = {
    error = "base0F";
    toolDiffRemoved = "base0F";
    warning = "base0E";
    syntaxNumber = "base0C";
    userMessageBg = "base02";
    customMessageBg = "base02";
    toolPendingBg = "base02";
    muted = "base05";
    thinkingText = "base05";
    customMessageText = "base05";
    toolOutput = "base05";
    toolDiffContext = "base05";
    syntaxComment = "base05";
    text = "base08";
    userMessageText = "base08";
    toolTitle = "base08";
    dim = "base04";
    borderMuted = "base04";
    mdCodeBlockBorder = "base04";
    mdQuoteBorder = "base04";
    mdHr = "base04";
  };

  resolved =
    defaultRoles
    // lib.optionalAttrs (colors.slug == "tokyo-night-dark") tokyoNightDarkOverrides;

  blend = fgSlot: pct: let
    mix = channel: let
      bg = lib.toInt colors."base00-rgb-${channel}";
      fg = lib.toInt colors."${fgSlot}-rgb-${channel}";
    in
      (bg * (100 - pct) + fg * pct + 50) / 100;
    toHex = n: lib.fixedWidthString 2 "0" (lib.toHexString n);
  in "#${toHex (mix "r")}${toHex (mix "g")}${toHex (mix "b")}";

  export = {
    pageBg = colors.withHashtag.base00;
    infoBg = colors.withHashtag.base02;
    cardBg =
      if colors.slug == "tokyo-night-dark"
      then colors.withHashtag.base02
      else colors.withHashtag.base01;
  };
in {
  programs.pi.themes.stylix =
    lib.optionalAttrs (lib.elem config.stylix.polarity ["dark" "light"]) {
      appearance = config.stylix.polarity;
    }
    // {
      inherit vars export;
      colors =
        resolved
        // {
          toolSuccessBg = blend resolved.success 15;
          toolErrorBg = blend resolved.error 15;
        };
    };
})
