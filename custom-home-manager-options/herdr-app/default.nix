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
  # ponytail: a key removed from Nix stays in the live file; delete it there by hand.
  mergeJson = name: value: let
    nixValue = jsonFormat.generate "herdr-app-${name}" value;
  in
    lib.optionalString (value != {}) ''
      target=${lib.escapeShellArg "${configDir}/${name}"}
      run mkdir -p ${lib.escapeShellArg configDir}
      if [ -s "$target" ]; then
        merged="$(mktemp)"
        ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$target" ${nixValue} > "$merged"
        run install -m 644 "$merged" "$target"
        rm -f "$merged"
      else
        run install -m 644 ${nixValue} "$target"
      fi
    '';
  # Overwrites the mod's files in place; files Herdr generates there (jsconfig.json, .d.ts) stay.
  # ponytail: a file deleted from the Nix mod folder stays in the live folder; delete it there by hand.
  copyMod = name: dir: let
    target = lib.escapeShellArg "${configDir}/mods/${name}";
  in ''
    run mkdir -p ${target}
    run ${pkgs.coreutils}/bin/cp -rT --no-preserve=mode,ownership ${dir} ${target}
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
