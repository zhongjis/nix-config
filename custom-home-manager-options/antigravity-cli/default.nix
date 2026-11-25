# Mutable settings for the upstream programs.antigravity-cli module.
#
# agy rewrites ~/.gemini/antigravity-cli/settings.json on every start (one-step
# replace, mode 0600) and on /model, /permissions and trust prompts, so a
# read-only Home Manager link cannot own it. Activation merges managedSettings
# into the live file instead: managed keys win, permission lists are unioned,
# and keys agy owns (model, trustedWorkspaces, gcp) are kept.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.antigravity-cli;
  jsonFormat = pkgs.formats.json {};
  settingsPath = "${config.home.homeDirectory}/.gemini/antigravity-cli/settings.json";
  managedFile = jsonFormat.generate "antigravity-cli-managed-settings.json" cfg.managedSettings;
  jq = lib.getExe pkgs.jq;
in {
  options.programs.antigravity-cli.managedSettings = lib.mkOption {
    type = jsonFormat.type;
    default = {};
    description = ''
      Settings merged into ~/.gemini/antigravity-cli/settings.json on every
      activation. Managed keys overwrite live values; permissions.allow, ask and
      deny are unioned with rules agy saved at runtime. Other keys stay mutable.
    '';
  };

  config = lib.mkIf (cfg.enable && cfg.managedSettings != {}) {
    home.activation.antigravityCliSettings = lib.hm.dag.entryAfter ["linkGeneration"] ''
      agy_settings=${lib.escapeShellArg settingsPath}
      if [ -L "$agy_settings" ]; then
        warnEcho "Skipping $agy_settings: it is a symlink. Unset programs.antigravity-cli.settings."
      elif [ -s "$agy_settings" ] && ! ${jq} -e 'type == "object"' "$agy_settings" > /dev/null 2>&1; then
        warnEcho "Skipping $agy_settings: not a JSON object. Fix it or let agy recover it, then switch again."
      else
        agy_tmp="$(mktemp)"
        { if [ -s "$agy_settings" ]; then cat "$agy_settings"; else echo '{}'; fi; } \
          | ${jq} --slurpfile managed ${managedFile} -f ${./merge-settings.jq} > "$agy_tmp"
        if ! { [ -s "$agy_settings" ] && ${jq} -e -n --slurpfile a "$agy_settings" --slurpfile b "$agy_tmp" '$a == $b' > /dev/null; }; then
          $DRY_RUN_CMD install -D -m 600 "$agy_tmp" "$agy_settings"
        fi
        rm -f "$agy_tmp"
      fi
    '';
  };
}
