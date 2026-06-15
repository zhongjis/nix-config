{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.codex;
  tomlFormat = pkgs.formats.toml {};
  codexConfigPath = "${config.home.homeDirectory}/.codex/config.toml";
  codexConfigSeed = tomlFormat.generate "codex-config-seed.toml" cfg.seedSettings;
  tomlkitPython = pkgs.python3.withPackages (pythonPackages: [pythonPackages.tomlkit]);
  mergeScript = pkgs.writeText "merge-codex-config.py" ''
    import sys
    from pathlib import Path

    import tomlkit

    seed_path = Path(sys.argv[1])
    config_path = Path(sys.argv[2])

    seed_doc = tomlkit.parse(seed_path.read_text())
    config_doc = tomlkit.parse(config_path.read_text() if config_path.exists() else "")

    def merge_missing(target, source):
        changed = False
        for key, value in source.items():
            if key not in target:
                target[key] = value
                changed = True
                continue

            target_value = target[key]
            if hasattr(target_value, "items") and hasattr(value, "items"):
                changed = merge_missing(target_value, value) or changed
        return changed

    if merge_missing(config_doc, seed_doc):
        config_path.write_text(tomlkit.dumps(config_doc))
  '';
in {
  options.programs.codex.seedSettings = lib.mkOption {
    type = tomlFormat.type;
    default = {};
    description = ''
      TOML settings to seed into ~/.codex/config.toml while leaving the live
      Codex config mutable. Missing keys are added during activation; existing
      user- or Codex-written values are preserved.
    '';
  };

  config = lib.mkIf (cfg.seedSettings != {}) {
    home.activation.seedCodexConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
      codex_config=${lib.escapeShellArg codexConfigPath}
      codex_seed=${lib.escapeShellArg "${codexConfigSeed}"}

      if [ -L "$codex_config" ]; then
        target="$(readlink "$codex_config")"
        case "$target" in
          /nix/store/*)
            $DRY_RUN_CMD rm -f "$codex_config"
            ;;
        esac
      fi

      if [ ! -e "$codex_config" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$codex_config")"
        $DRY_RUN_CMD install -m 0600 "$codex_seed" "$codex_config"
      elif [ -f "$codex_config" ]; then
        $DRY_RUN_CMD ${tomlkitPython}/bin/python ${mergeScript} "$codex_seed" "$codex_config"
      fi
    '';
  };
}
