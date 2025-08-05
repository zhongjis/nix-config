{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = {
    enable = true;
    policies = let
      locked = value: {
        Value = value;
        Status = "locked";
      };
    in {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true; # save webs for later reading
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      Preferences = builtins.mapAttrs (_: locked) {
        "browser.tabs.warnOnClose" = false;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;
      };
    };
  };

  # NOTE: for some reason this only works under stylix.nix under hm module
  # stylix.targets.zen-browser.profileNames = lib.singleton "default";
}
