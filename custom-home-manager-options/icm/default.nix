{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.icm;
  tomlFormat = pkgs.formats.toml {};

  defaultIcmPackage =
    if inputs ? llm-agents
    then inputs.llm-agents.packages.${system}.icm
    else null;

  claudeEnabled = config.programs.claude-code.icm.enable;
  codexEnabled = config.programs.codex.icm.enable;
  piEnabled = config.programs.pi.icm.enable;
  opencodeEnabled = config.programs.opencode.icm.enable;
  anyEnabled = claudeEnabled || codexEnabled || piEnabled || opencodeEnabled;

  # Stable profile path, not a /nix/store path, so hooks survive package bumps.
  # Also the marker that identifies icm-owned hook entries for removal.
  icmBin = "${config.home.profileDirectory}/bin/icm";
  hookMarker = "${icmBin} hook ";

  hookEntry = event: matcher:
    {
      hooks = [
        {
          type = "command";
          command = "${hookMarker}${event}";
        }
      ];
    }
    // lib.optionalAttrs (matcher != null) {inherit matcher;};

  claudeHooks = {
    SessionStart = [(hookEntry "start" null)];
    PreToolUse = [(hookEntry "pre" "Bash")];
    PostToolUse = [(hookEntry "post" null)];
    UserPromptSubmit = [(hookEntry "prompt" null)];
    PreCompact = [(hookEntry "compact" null)];
    SessionEnd = [(hookEntry "end" null)];
  };

  # No PostToolUse: Codex fires it on every shell command and floods the store (icm #288).
  codexHooks = {
    SessionStart = [(hookEntry "start" null)];
    PreToolUse = [(hookEntry "pre" "Bash")];
    UserPromptSubmit = [(hookEntry "prompt" null)];
  };

  # Strips every icm-owned entry (matched by hookMarker), then re-adds the wanted
  # ones when enabled. Other hooks and keys are left untouched.
  mergeHooksFilter = pkgs.writeText "icm-merge-hooks.jq" ''
    def isIcm: any((.hooks // [])[]; ((.command // "") | type) == "string" and ((.command // "") | startswith($marker)));
    (has("hooks")) as $hadHooks
    | .hooks = ((.hooks // {}) | with_entries(
        if (.value | type) == "array" and (.value | any(isIcm))
        then (.value |= map(select(isIcm | not))) | select(.value != [])
        else .
        end))
    | if $enable
      then reduce ($entries | to_entries[]) as $e (.; .hooks[$e.key] = ((.hooks[$e.key] // []) + $e.value))
      else .
      end
    | if (.hooks == {}) and ($hadHooks | not) then del(.hooks) else . end
  '';

  mergeHooksScript = file: enable: entries: ''
    icm_file=${lib.escapeShellArg file}
    if [ -f "$icm_file" ] || ${lib.boolToString enable}; then
      if [ ! -e "$icm_file" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$icm_file")"
        $DRY_RUN_CMD sh -c 'printf "{}\n" > "$1"' sh "$icm_file"
      fi
      if [ -f "$icm_file" ]; then
        icm_tmp="$(mktemp)"
        ${lib.getExe pkgs.jq} \
          --arg marker ${lib.escapeShellArg hookMarker} \
          --argjson enable ${lib.boolToString enable} \
          --argjson entries ${lib.escapeShellArg (builtins.toJSON entries)} \
          -f ${mergeHooksFilter} "$icm_file" > "$icm_tmp"
        # Write only on a semantic change so repeated switches leave the file byte-identical.
        if ! ${lib.getExe pkgs.jq} -e -n --slurpfile a "$icm_file" --slurpfile b "$icm_tmp" '$a == $b' > /dev/null; then
          $DRY_RUN_CMD sh -c 'cat "$1" > "$2"' sh "$icm_tmp" "$icm_file"
        fi
        rm -f "$icm_tmp"
      fi
    fi
  '';

  # Adapted from icm's built-in AGENTS.md block (crates/icm-cli/src/main.rs, `icm init --mode cli`).
  piContext = ''
    ## Persistent memory (ICM)

    [ICM](https://github.com/rtk-ai/icm) provides persistent memory shared across sessions and agents.
    Use it actively.

    ### Recall (before starting work)
    ```bash
    icm recall "query"                        # search memories
    icm recall "query" -t "topic-name"        # filter by topic
    icm recall-context "query" --limit 5      # formatted for prompt injection
    ```

    ### Store triggers
    Call `icm store` when any of the following happens:
    1. **Error resolved**: `icm store -t errors-resolved -c "description" -i high -k "keyword1,keyword2"`
    2. **Architecture/design decision**: `icm store -t decisions-{project} -c "description" -i high`
    3. **User preference discovered**: `icm store -t preferences -c "description" -i critical`
    4. **Significant task completed**: `icm store -t context-{project} -c "summary of work done" -i high`
    5. **Conversation exceeds ~20 tool calls without a store**: store a progress summary

    Do NOT store: trivial details, info already in this file, ephemeral state (build logs, git status), secrets.

    ### Other commands
    ```bash
    icm forget <id>                          # remove a memory by ID
    icm list --all                           # list all memories
    icm list --topic <name>                  # list memories in a topic
    icm update <id> -c "updated content"     # edit memory in-place
    icm topics                               # list all topics
    ```
  '';

  # Adapted from icm's built-in /icm-recall and /icm-remember prompts to Pi SKILL.md frontmatter.
  piSkills = {
    icm-recall = pkgs.writeTextDir "SKILL.md" ''
      ---
      name: icm-recall
      description: Search ICM persistent memory. Use when the user asks to recall, look up, or check what is remembered about a topic, or before starting work that may depend on earlier sessions.
      ---

      # icm-recall

      Search ICM memory for the user's query. Run:

      ```bash
      icm recall "<query>" --limit 10
      ```

      With no query, load the wake-up pack instead:

      ```bash
      icm wake-up --max-tokens 800
      ```
    '';
    icm-remember = pkgs.writeTextDir "SKILL.md" ''
      ---
      name: icm-remember
      description: Store a fact in ICM persistent memory. Use when the user says remember this, save this to memory, or asks to store a decision, preference, or lesson.
      ---

      # icm-remember

      Store the user's text in ICM memory. Run:

      ```bash
      icm remember "<text>"
      ```
    '';
  };

  # Lazy: only evaluated when OpenCode integration is enabled.
  icmSrc = pkgs.fetchFromGitHub {
    owner = "rtk-ai";
    repo = "icm";
    rev = "icm-v${cfg.package.version}";
    hash = "sha256-iihIM/MVAR5zmFIzo5oUgtOkOCf8474W/AwrbJUVkno=";
  };
in {
  options.programs.icm = {
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultIcmPackage;
      defaultText = lib.literalExpression "inputs.llm-agents.packages.\${pkgs.stdenv.hostPlatform.system}.icm";
      description = "icm package shared by every agent integration.";
    };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = {};
      description = "icm config.toml contents, written where icm reads its user config.";
    };
  };

  options.programs.claude-code.icm.enable = lib.mkEnableOption "icm hooks for Claude Code";
  options.programs.codex.icm.enable = lib.mkEnableOption "icm hooks for Codex";
  options.programs.pi.icm.enable = lib.mkEnableOption "icm context and skills for Pi";
  options.programs.opencode.icm.enable = lib.mkEnableOption "icm plugin for OpenCode";

  config = lib.mkMerge [
    {
      # Runs even when disabled so turning a toggle off removes icm's entries.
      home.activation.icmClaudeHooks = lib.hm.dag.entryAfter ["linkGeneration"] (
        mergeHooksScript "${config.home.homeDirectory}/.claude/settings.json" claudeEnabled claudeHooks
      );
      home.activation.icmCodexHooks = lib.hm.dag.entryAfter ["linkGeneration"] (
        mergeHooksScript "${config.home.homeDirectory}/.codex/hooks.json" codexEnabled codexHooks
      );
    }
    (lib.mkIf anyEnabled {
      assertions = [
        {
          assertion = cfg.package != null;
          message = ''
            programs.icm.package must be set when an icm integration is enabled.
            If you import this module outside this flake, pass the package explicitly or provide inputs.llm-agents.
          '';
        }
      ];

      # summarizer `auto`: hook-driven extraction (Claude Code) runs through the
      # invoking agent's CLI; Pi's icm extension extracts with Pi's model only
      # under `auto`. No raw tool-output dumps. [store].path is left unset so
      # per-repo .icm/ databases keep working.
      programs.icm.settings.extraction = {
        store_raw = false;
        summarizer.provider = "auto";
      };

      home.packages = [cfg.package];

      home.file."icm/config.toml" = {
        target =
          if pkgs.stdenv.hostPlatform.isDarwin
          then "Library/Application Support/dev.icm.icm/config.toml"
          else "${config.xdg.configHome}/icm/config.toml";
        source = tomlFormat.generate "icm-config.toml" cfg.settings;
      };
    })
    (lib.mkIf piEnabled {
      programs.pi.context = lib.mkAfter piContext;
      programs.pi.skills = piSkills;
    })
    (lib.mkIf opencodeEnabled {
      xdg.configFile."opencode/plugins/icm.ts".source = icmSrc + "/plugins/opencode-icm.ts";
    })
  ];
}
