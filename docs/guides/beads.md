# Global beads

The ai-tools feature enables `programs.beads` and `programs.beads.server.enable`.
The module is also exported as `homeManagerModules.beads`. Set `package` to
override the CLI; `settings` supplies non-secret `bd config set` values after
each start. Disabling `server.enable` keeps only the CLI installed.

## Database and login service

`BEADS_DIR` selects `$XDG_DATA_HOME/beads/global/.beads`;
`BEADS_DOLT_SHARED_SERVER=1` selects bd's shared local server. The parent
`global` directory is the initialization anchor, not `.beads` itself.
The service uses bd's default port and server data directory, without a
restart policy, remote, or auto-commit override.

Linux uses `beads.service`, a systemd user oneshot with `RemainAfterExit`.
macOS uses the `org.nix-community.home.beads` launchd agent. Its wrapper stays
alive so launchd termination runs `bd dolt stop`. Both start with
`bd dolt start`, then run idempotent `bd init --shared-server --init-if-missing`
without installing agent files or git hooks. The bootstrap seeds a writable
`config.yaml` workspace marker before starting. Init uses
`--db "$BEADS_DIR/dolt" --database global` so bd 1.3.4 persists anchor metadata
when shared storage lives elsewhere; this does not move the shared server data. [4]

The module installs `PRIME.md` inside the anchor's `.beads`. In bd 1.3.4,
`bd prime` checks the current directory's `.beads/PRIME.md` first, then the
resolved `BEADS_DIR/PRIME.md`, then the user config directory. A project-local
override therefore takes precedence over the installed global guidance. [1]

## Pull-only tracker setup

The personal profile exports `LINEAR_TEAM_ID` for A2A and reads
`LINEAR_API_KEY` from its sops secret when the session environment loads.
The login bootstrap sets `linear.state_map.*`: backlog, unstarted and started
are open; completed and canceled are closed. Unknown states fall back to open. [2]

Work-profile tracker credentials and configuration stay in `nix-config-private`.
Jira 1.3.4 uses `jira.status_map.<beads-status>=<one Jira state name>`, not an
arbitrary inbound state map. Configuring the closed alias to Cancelled retains
the built-in Done/Closed/Resolved closed mappings. In Progress and In Review
still import as `in_progress`; Blocked still imports as `blocked`. Other unknown
names default to open. [3] Ticket wf-zr1.3 owns post-pull normalization to open.
No tracker pull, sync or push runs during activation or service startup.

## Verify and apply

```sh
nix eval --impure --raw --expr '(import ./tests/beads.nix).drvPath'
nh home switch .
systemctl --user status beads.service
zsh -lc 'bd ping; bd prime'
```

The eval check covers Linux and Darwin definitions, session variables,
disabled-server behavior, custom XDG data location and PRIME installation.
macOS activation must be exercised on a Mac; Linux cannot execute launchd.

Sources:
[1] [bd 1.3.4 PRIME resolution](https://github.com/steveyegge/beads/blob/v1.3.4/cmd/bd/prime.go)
[2] [bd 1.3.4 Linear mapping](https://github.com/steveyegge/beads/blob/v1.3.4/internal/linear/mapping.go)
[3] [bd 1.3.4 Jira mapping](https://github.com/steveyegge/beads/blob/v1.3.4/internal/jira/fieldmapper.go)
[4] [bd 1.3.4 shared-server initialization](https://github.com/steveyegge/beads/blob/v1.3.4/cmd/bd/init.go)
