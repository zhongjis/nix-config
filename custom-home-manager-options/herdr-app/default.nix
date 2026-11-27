{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  inherit (lib) mkIf mkOption types;
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.herdr-app;
  jsonFormat = pkgs.formats.json {};
  configDir = "${config.xdg.configHome}/herdr-app";

  # Herdr App also writes settings.json (zoom, Settings screen) and keys.json (rebinds),
  # so these are merged over the live file instead of linked read-only.
  # keys.json goes through merge-keys.sh, which keeps a manifest of the last value Nix wrote per key path
  # ($XDG_STATE_HOME/herdr-app/managed-keys.json): a path Nix dropped is deleted from the live file only while its
  # value is still the managed one, so a binding removed from Nix goes away and a rebind made by hand stays.
  # ponytail: settings.json has no manifest, so a setting removed from Nix stays in the live file; delete it by hand.
  # Upgrade path: the same script for settings.
  mergeJson = name: value: let
    nixValue = jsonFormat.generate "herdr-app-${name}" value;
    jq = lib.getExe pkgs.jq;
  in
    if name == "keys.json"
    then ''
      run ${pkgs.bash}/bin/bash ${./merge-keys.sh} ${jq} ${lib.escapeShellArg "${configDir}/${name}"} ${lib.escapeShellArg "${config.xdg.stateHome}/herdr-app/managed-keys.json"} ${nixValue}
    ''
    else
      lib.optionalString (value != {}) ''
        target=${lib.escapeShellArg "${configDir}/${name}"}
        run mkdir -p ${lib.escapeShellArg configDir}
        if [ -s "$target" ]; then
          merged="$(mktemp)"
          ${jq} -s '.[0] * .[1]' "$target" ${nixValue} > "$merged"
          run install -m 644 "$merged" "$target"
          rm -f "$merged"
        else
          run install -m 644 ${nixValue} "$target"
        fi
      '';
  # Overwrites the mod's files in place; files Herdr generates there (jsconfig.json, .d.ts) stay.
  # Symlinks are copied as the files they point to: Herdr refuses imports from outside the mod folder.
  # The relative files copied are recorded in $XDG_STATE_HOME/herdr-app/mods/<name>.files; a file listed there
  # that the Nix mod folder no longer has is deleted. Nothing outside that list is ever deleted.
  # Files a mod lost before its first file list existed: the first activation with the list removes them too.
  removedBeforeList = {
    fleet = ["beads.js" "task.svg"];
  };
  copyMod = name: dir: let
    target = lib.escapeShellArg "${configDir}/mods/${name}";
    files = lib.escapeShellArg "${config.xdg.stateHome}/herdr-app/mods/${name}.files";
    removed = removedBeforeList.${name} or [];
  in ''
    run mkdir -p ${target} ${lib.escapeShellArg "${config.xdg.stateHome}/herdr-app/mods"}
    newFiles="$(mktemp)"
    oldFiles="$(mktemp)"
    goneFiles="$(mktemp)"
    (cd ${dir} && find -L . -type f -printf '%P\n' | LC_ALL=C sort) > "$newFiles"
    run ${pkgs.coreutils}/bin/cp -rTL --no-preserve=mode,ownership ${dir} ${target}
    if [ -s ${files} ]; then
      cat ${files} > "$oldFiles"
    ${lib.optionalString (removed != []) ''
      else
        printf '%s\n' ${lib.concatMapStringsSep " " lib.escapeShellArg removed} > "$oldFiles"
    ''}
    fi
    if [ -s "$oldFiles" ]; then
      LC_ALL=C sort "$oldFiles" | LC_ALL=C comm -23 - "$newFiles" > "$goneFiles"
      while IFS= read -r gone; do
        case "$gone" in
          "" | /* | .. | ../* | */.. | */../*) continue ;;
        esac
        run rm -f -- ${target}/"$gone"
      done < "$goneFiles"
    fi
    run install -m 644 "$newFiles" ${files}
    rm -f "$newFiles" "$oldFiles" "$goneFiles"
  '';
in {
  options.programs.herdr-app = {
    enable = lib.mkEnableOption "Herdr App";

    package = mkOption {
      type = types.nullOr types.package;
      default = inputs.llm-agents.packages.${system}.herdr-app or null;
      defaultText = lib.literalExpression "inputs.llm-agents.packages.\${system}.herdr-app";
      description = "Herdr App package to install, or null to skip installing it.";
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = {};
      example = {telemetry = false;};
      description = ''
        Values merged into {file}`$XDG_CONFIG_HOME/herdr-app/settings.json` on activation.
        The file stays writable, so values the app saves itself (zoom) are kept.
      '';
    };

    keys = mkOption {
      inherit (jsonFormat) type;
      default = {};
      example = {"layout:main"."ctrl-shift-s" = "agents.settle";};
      description = ''
        Key bindings merged into {file}`$XDG_CONFIG_HOME/herdr-app/keys.json` on activation.
      '';
    };

    layouts = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = {};
      description = "Layouts linked read-only to {file}`$XDG_CONFIG_HOME/herdr-app/layouts/<name>.json`.";
    };

    themes = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = {};
      description = "Themes linked read-only to {file}`$XDG_CONFIG_HOME/herdr-app/themes/<name>.json`.";
    };

    mods = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = ''
        Mod folders copied into {file}`$XDG_CONFIG_HOME/herdr-app/mods/<name>/` on activation.
        Herdr App refuses mod imports that resolve outside the mod folder, so store links fail.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [cfg.package];

    xdg.configFile =
      lib.mapAttrs' (name: layout:
        lib.nameValuePair "herdr-app/layouts/${name}.json" {
          source = jsonFormat.generate "herdr-app-layout-${name}.json" layout;
        })
      cfg.layouts
      // lib.mapAttrs' (name: theme:
        lib.nameValuePair "herdr-app/themes/${name}.json" {
          source = jsonFormat.generate "herdr-app-theme-${name}.json" theme;
        })
      cfg.themes;

    home.activation.herdrAppConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${mergeJson "settings.json" cfg.settings}
      ${mergeJson "keys.json" cfg.keys}
      ${lib.concatStrings (lib.mapAttrsToList copyMod cfg.mods)}
    '';
  };
}
