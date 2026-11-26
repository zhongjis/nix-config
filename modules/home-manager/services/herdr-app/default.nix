{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  stylixEnabled = config.stylix.enable or false;
  fleetKey =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "cmd-shift-a"
    else "ctrl-shift-a";
  # panda-focus's session hooks, passed per launch instead of installed into Claude Code, Pi, Codex and Copilot.
  # agy has no per-launch plugin flag: its hook is a plugin linked into agy's plugins folder below.
  integrations = "${config.xdg.configHome}/herdr-app/mods/panda-focus/integrations";
  # Runs the next `name` on PATH after itself; inside Herdr (HC_TERMINAL_ID) it adds `flags`.
  # PATH stays as it is, so the agent's children (start-worker.sh's `hc run`) keep the shims.
  agentShim = name: flags:
    pkgs.writeShellScriptBin name ''
      real=
      IFS=: read -ra dirs <<<"$PATH"
      for d in "''${dirs[@]}"; do
        if [ -x "$d/${name}" ] && ! [ "$d/${name}" -ef "$0" ]; then real=$d/${name}; break; fi
      done
      [ -n "$real" ] || { echo "${name}: not found on PATH" >&2; exit 127; }
      [ -n "''${HC_TERMINAL_ID:-}" ] || exec "$real" "$@"
      exec "$real" ${flags} "$@"
    '';
  agentShims = pkgs.symlinkJoin {
    name = "herdr-agent-shims";
    paths = [
      (agentShim "claude" "--plugin-dir ${lib.escapeShellArg "${integrations}/claude-plugin"}")
      (agentShim "pi" "-e ${lib.escapeShellArg "${integrations}/pi.ts"}")
      # Codex runs an inline hook only once trusted (/hooks); the trust is kept in ~/.codex/config.toml.
      (agentShim "codex" "-c ${lib.escapeShellArg ''hooks.SessionStart=[{hooks=[{type="command",command="sh ${integrations}/codex.sh",timeout=10}]}]''}")
      (agentShim "copilot" "--plugin-dir ${lib.escapeShellArg "${integrations}/copilot-plugin"}")
    ];
  };
in {
  imports = [
    ../../../../custom-home-manager-options/herdr-app
  ];

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr-core
    (pkgs.writeShellScriptBin "sessionizer" ''
      export PATH=${lib.makeBinPath [pkgs.jq pkgs.fzf pkgs.findutils pkgs.coreutils pkgs.gnused config.programs.herdr-app.package]}:"$PATH"
      ${builtins.readFile ./scripts/herdr-sessionizer.sh}
    '')
  ];

  # agy finds plugins (plugin.json plus a root hooks.json) in its plugins folder, symlinks included.
  # The hook itself does nothing outside Herdr terminals.
  home.file = lib.mkIf (config.programs.antigravity-cli.enable or false) {
    ".gemini/config/plugins/herdr-app-session/plugin.json".text = builtins.toJSON {
      name = "herdr-app-session";
      version = "1.0.0";
      description = "Herdr panda-focus session hook: labels agy terminals inside Herdr with their resume line.";
    };
    ".gemini/config/plugins/herdr-app-session/hooks.json".text = builtins.toJSON {
      herdr-resume.SessionStart = [
        {
          type = "command";
          command = "sh ${lib.escapeShellArg "${integrations}/agy.sh"}";
        }
      ];
    };
  };

  # Only Herdr's shells (agents from the app, typed, resumed after a reboot) see the shims.
  programs.zsh.initContent = lib.mkAfter ''
    [[ -n $HC_TERMINAL_ID ]] && path=(${agentShims}/bin $path)
  '';

  programs.herdr-app = {
    enable = true;
    settings =
      {
        telemetry = false;
        sounds.enabled = true;
      }
      // lib.optionalAttrs stylixEnabled ({
          font = config.stylix.fonts.monospace.name;
          theme = "stylix";
        }
        // lib.optionalAttrs (lib.elem config.stylix.polarity ["dark" "light"]) {
          appearance = config.stylix.polarity;
        });
    # Base16 palette in Herdr's theme format; the ANSI order matches Stylix's ghostty palette.
    themes = lib.optionalAttrs stylixEnabled {
      stylix = with config.lib.stylix.colors.withHashtag; {
        background = base00;
        foreground = base05;
        selection = base02;
        cursor = base05;
        ansi = [
          base00
          base08
          base0B
          base0A
          base0D
          base0E
          base0C
          base05
          base03
          base08
          base0B
          base0A
          base0D
          base0E
          base0C
          base07
        ];
        colors = {
          accent = base0D;
          working = base0A;
          blocked = base08;
          done = base0B;
          idle = base03;
        };
      };
    };
    keys = {
      global = {
        "ctrl-shift-f" = "mod.open:picker";
        "ctrl-b" = "mod.open:tmux-prefix";
        "cmd-e" = "mod.open:filetree";
        "cmd-shift-e" = "filetree.reveal";
        "cmd-o" = "filetree.recent";
        ${if pkgs.stdenv.hostPlatform.isDarwin then "cmd-shift-p" else "ctrl-shift-p"} = "app.palette";
      };
      # Herdr seeds its default keymap only into a new keys.json; one created by
      # activation first has none, so keep the terminal clipboard keys here.
      terminal = {
        "cmd-c" = "terminal.copy";
        "cmd-v" = "terminal.paste";
        "ctrl-v" = "terminal.paste_image";
        # tmux-style prefix (tmux-prefix mod); Ctrl+B twice sends a literal Ctrl+B.
        "ctrl-b" = "mod.open:tmux-prefix";
      };
      "mod:tmux-prefix"."ctrl-b" = "tmux-prefix.send-prefix";
      # Settle the focused agent in the herdr-panda sidebar (panda-focus mod).
      "layout:herdr-panda" = {
        "cmd-shift-s" = "panda-focus.settle";
        "ctrl-shift-s" = "panda-focus.settle";
      };
      # herdr-fleet: same settle keys; Cmd/Ctrl+Shift+A swaps the work area for the Agent Fleet (fleet mod) and back.
      "layout:herdr-fleet" = {
        "cmd-shift-s" = "panda-focus.settle";
        "ctrl-shift-s" = "panda-focus.settle";
        ${fleetKey} = {
          command = "layout.select";
          args = {
            stack = "work-switch";
            child = "fleet";
          };
        };
      };
      "mod:fleet".${fleetKey} = "fleet.toggle";
    };
    # Herdr's default `main` layout with the panda-focus agent cards in the sidebar.
    layouts.herdr-panda = lib.importJSON ./layouts/herdr-panda.json;
    # herdr-panda with its work area in a stack: the tabs' panes and panel, or the Agent Fleet.
    layouts.herdr-fleet = lib.importJSON ./layouts/herdr-fleet.json;
    # Mods linking files from mods/shared come from the whole mods folder, so the links resolve when copied.
    mods = {
      panda-focus = "${./mods}/panda-focus";
      panda-subagents = "${./mods}/panda-subagents";
      # Agent Fleet: agents, their workers and their beads as a tree; herdr-fleet's work-area alternative.
      fleet = ./mods/fleet;
      # The Agent Fleet's overlay prototype (mod.open fleet-proto), kept beside the fleet mod it became.
      fleet-proto = ./mods/fleet-proto;
      # Herdr's `spaces` mod with the repo/branch on its own line.
      panda-spaces = "${./mods}/panda-spaces";
      # panda-spaces' right-click menu on a worktree without a space.
      panda-worktree-menu = ./mods/panda-worktree-menu;
      # Herdr's `tabs` mod with icon-only Files/Changes/PR/CI panel buttons.
      panda-tabs = ./mods/panda-tabs;
      # Herdr's `workspace-chrome` footer (Settings, Add machine) with centered icons on the collapsed rail.
      panda-chrome = ./mods/panda-chrome;
      # Replaces Herdr's shipped `changes` panel (reuses its git listing): inline diffs, opens hunk, sends hunk notes to the tab's agent.
      hunk-review = ./mods/hunk-review;
      # herdr.dev/mods/herdrdev/tmux-prefix
      tmux-prefix = ./mods/tmux-prefix;
      # Vendored and customized (not pinned); upstream LICENSE kept in each folder.
      # github.com/cybertron288/herdr-mods filetree with ChmaraX/herdr-nvim's vendored controller.
      filetree = ./mods/filetree;
      # github.com/cybertron288/herdr-mods file-icons; filetree reads its icons/.
      file-icons = ./mods/file-icons;
      # github.com/jjangsky/herdr-pr-flow, fed by panda-spaces' PR list.
      pr-flow = ./mods/pr-flow;
      # github.com/cybertron288/herdr-mods ci-dash (GitHub Actions runs, dispatch, artifacts).
      ci-dash = ./mods/ci-dash;
      # github.com/DeevsDeevs/deevs-herdr-kit agent-browser.
      agent-browser = ./mods/agent-browser;
      # Jira + Linear issue popup; UI adapted from github.com/mrolafsson/herdr-linear.
      issues = ./mods/issues;
    };
  };
}
