{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  defaultRtkPackage =
    if inputs ? llm-agents
    then inputs.llm-agents.packages.${system}.rtk
    else null;

  opencodeRtkCfg = config.programs.opencode.rtk;
  ompRtkCfg = config.programs."oh-my-pi".rtk;
  piRtkCfg = config.programs.pi.rtk;
  claudeRtkEnabled = config.programs.claude-code.rtk.enable;

  # Stable profile path, not a /nix/store path, so the hook survives package bumps.
  # Also the marker that identifies the RTK-owned hook entry for removal.
  claudeRtkHook = "${config.home.profileDirectory}/bin/rtk hook claude";
  claudeRtkHookEntry = {
    matcher = "Bash";
    hooks = [
      {
        type = "command";
        command = claudeRtkHook;
      }
    ];
  };

  # Lazy: only evaluated when a consumer that sources upstream hooks is enabled (opencode or pi).
  rtkPluginSrc = pkgs.fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${defaultRtkPackage.version}";
    hash = "sha256-ZCDVS/AFljljMac+cAzQztYPQgvQrcEhKIHHRhkMsv8=";
  };
in {
  options.programs.claude-code.rtk.enable =
    lib.mkEnableOption "RTK PreToolUse hook and output note for Claude Code";

  options.programs.opencode.rtk.enable =
    lib.mkEnableOption "RTK integration for OpenCode";

  options.programs."oh-my-pi".rtk = {
    enable = lib.mkEnableOption "RTK integration for Oh My Pi";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultRtkPackage;
      defaultText = lib.literalExpression "inputs.llm-agents.packages.\${pkgs.stdenv.hostPlatform.system}.rtk";
      description = "RTK runtime package installed when programs.\"oh-my-pi\".rtk.enable is true.";
    };

    extension = lib.mkOption {
      type = lib.types.path;
      default = ./extensions/rtk.ts;
      defaultText = lib.literalExpression "./rtk/extensions/rtk.ts";
      description = "Extension file exposed as ~/.omp/agent/extensions/rtk.ts when programs.\"oh-my-pi\".rtk.enable is true.";
    };
  };

  options.programs.pi.rtk = {
    enable = lib.mkEnableOption "RTK integration for Pi";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultRtkPackage;
      defaultText = lib.literalExpression "inputs.llm-agents.packages.\${pkgs.stdenv.hostPlatform.system}.rtk";
      description = "RTK runtime package installed when programs.pi.rtk.enable is true.";
    };

    extension = lib.mkOption {
      type = lib.types.path;
      default = rtkPluginSrc + "/hooks/pi/rtk.ts";
      defaultText = lib.literalExpression "rtkPluginSrc + \"/hooks/pi/rtk.ts\"";
      description = "Extension file exposed as ~/.pi/agent/extensions/rtk.ts when programs.pi.rtk.enable is true.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !ompRtkCfg.enable || ompRtkCfg.package != null;
          message = ''
            programs."oh-my-pi".rtk.package must be set when programs."oh-my-pi".rtk.enable is true.
            If you import this module outside this flake, pass the package explicitly or provide inputs.llm-agents.
          '';
        }
        {
          assertion = !piRtkCfg.enable || piRtkCfg.package != null;
          message = ''
            programs.pi.rtk.package must be set when programs.pi.rtk.enable is true.
            If you import this module outside this flake, pass the package explicitly or provide inputs.llm-agents.
          '';
        }
      ];
    }
    {
      # Runs even when disabled so turning the toggle off removes RTK's hook.
      # Other hooks and keys in the writable settings.json are left untouched.
      home.activation.rtkClaudeHook = lib.hm.dag.entryAfter ["linkGeneration"] ''
        rtk_file=${lib.escapeShellArg "${config.programs.claude-code.configDir}/settings.json"}
        if [ -f "$rtk_file" ] || ${lib.boolToString claudeRtkEnabled}; then
          [ -e "$rtk_file" ] || { $DRY_RUN_CMD mkdir -p "$(dirname "$rtk_file")"; $DRY_RUN_CMD sh -c 'printf "{}\n" > "$1"' sh "$rtk_file"; }
          if [ -f "$rtk_file" ]; then
            rtk_tmp="$(mktemp)"
            ${lib.getExe pkgs.jq} \
              --arg cmd ${lib.escapeShellArg claudeRtkHook} \
              --argjson enable ${lib.boolToString claudeRtkEnabled} \
              --argjson entry ${lib.escapeShellArg (builtins.toJSON claudeRtkHookEntry)} '
                # Also claims a bare `rtk hook claude` entry left by `rtk init -g`.
                def isRtk: any((.hooks // [])[]; (.command? // "") | type == "string" and (. == $cmd or . == "rtk hook claude"));
                (.hooks.PreToolUse // [] | map(select(isRtk | not))) as $pre
                | ($pre + (if $enable then [$entry] else [] end)) as $pre
                | if $pre == [] then del(.hooks.PreToolUse) else .hooks.PreToolUse = $pre end
                | if .hooks == {} then del(.hooks) else . end
              ' "$rtk_file" > "$rtk_tmp"
            # Write only on a semantic change so repeated switches leave the file byte-identical.
            if ! ${lib.getExe pkgs.jq} -e -n --slurpfile a "$rtk_file" --slurpfile b "$rtk_tmp" '$a == $b' > /dev/null; then
              $DRY_RUN_CMD sh -c 'cat "$1" > "$2"' sh "$rtk_tmp" "$rtk_file"
            fi
            rm -f "$rtk_tmp"
          fi
        fi
      '';
    }
    (lib.mkIf claudeRtkEnabled {
      home.packages = [defaultRtkPackage];
      # Same note `rtk init -g` writes to ~/.claude/RTK.md, loaded as a rule instead.
      programs.claude-code.rules."rtk" =
        /*
        markdown
        */
        ''
          # Command output

          Command output here is condensed to save tokens, keeping every signal and
          dropping costly noise. Treat it as the complete result: run commands
          normally, and batch related commands into one call to avoid extra turns.
          Truncated results state their recovery path in their own output. Re-run a
          command as `rtk bypass <cmd>` only when its result is unusable: empty when
          output was clearly expected, contradicting its exit code, or garbled.
        '';
    })
    (lib.mkIf (claudeRtkEnabled || opencodeRtkCfg.enable || ompRtkCfg.enable || piRtkCfg.enable) {
      home.file."rtk/config.toml" = {
        target =
          if pkgs.stdenv.hostPlatform.isDarwin
          then "Library/Application Support/rtk/config.toml"
          else "${config.xdg.configHome}/rtk/config.toml";
        source = (pkgs.formats.toml {}).generate "rtk-config.toml" {
          # Diffs are the work product reviewers and implementers read; rtk's
          # compaction truncates large diffs, so pass them through unfiltered.
          hooks.exclude_commands = [
            "pnpm lint"
            "pnpm run lint"
            "biome"
            "^git (-C [^ ]+ )?(diff|show)( |$)"
            "^gh pr diff"
          ];
          telemetry.enabled = false;
          retriever.mode = "tee";
        };
      };
    })
    (lib.mkIf opencodeRtkCfg.enable {
      home.packages = [defaultRtkPackage];
      xdg.configFile."opencode/plugins/rtk.ts".source =
        rtkPluginSrc + "/hooks/opencode-rtk.ts";
    })
    (lib.mkIf ompRtkCfg.enable {
      home.packages = [ompRtkCfg.package];
      programs."oh-my-pi".extensions."rtk.ts" = ompRtkCfg.extension;
    })
    (lib.mkIf piRtkCfg.enable {
      home.packages = [piRtkCfg.package];
      programs.pi.extensions."rtk.ts" = piRtkCfg.extension;
    })
  ];
}
