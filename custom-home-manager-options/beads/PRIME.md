# Machine-wide beads

## What this is
One local database tracks work across this machine, not across machines.
BEADS_DIR selects it; BEADS_DOLT_SHARED_SERVER selects its local shared server.
The login service owns server startup. Report a blocker if `bd ping` fails.
The database is never pushed and has no Dolt remote.

## Read a bead
A bead has an id, title, description, status, priority, type and assignee.
Acceptance criteria define done; design holds decisions; notes hold current thinking.
Run `bd show <id> --json` before changing a bead.
Use `bd comments <id>` to read milestones and handoffs.

## Find your work
If ORCH_BEAD is set, start with `bd show "$ORCH_BEAD" --json`.
Otherwise find or create your own session epic and inspect its children.
Use only `bd ready --parent <epic> --json` to find ready work.
Never run unscoped `bd ready` or use `--claim` with readiness queries.
Ready means dependencies allow work; it does not grant ownership.
Statuses: open = not started; in_progress = claimed; blocked = waiting; closed = done.

## Structure and dependencies
An epic groups a session's work; a parent scopes its child beads.
Keep each task under the session epic that owns it.
A `blocks` dependency makes one bead wait for another.
Read parents and blockers before starting; do not remove someone else's links.

## Ownership
BEADS_ACTOR identifies you; an assignee matching it marks work you own.
In a plain session, a bead you created also belongs to you.
For other people's beads, only show and comment; do not change their fields.
An assigned worker follows its standing contract, even on its own bead.

## Notepad and comments
The notes field of a bead you own is one living notepad.
Replace it with the current plan, now and findings; keep it about one page.
Comments are append-only milestones, questions and reports, not a second notepad.
Start each milestone comment with `event=<name>` on its first line.

## Plain-session tracking
Set BEADS_ACTOR to your unique session name before creating plain-session work.
Create a session epic, then create your tasks under that epic.
Claim your own open task with `bd update <id> --assignee "$BEADS_ACTOR" --status in_progress --if-status open`.
Close only your own finished tasks with `bd close <id>`.
Leave incomplete tasks visible; do not close work merely because the session ends.

## Memory and forbidden operations
Durable lessons go to ICM, not `bd remember` or beads memories.
Never run `bd dolt push`, tracker sync or tracker push.
Never use `bd edit` or `bd delete`.
Only the designated orchestrator may run tracker pull; other agents report import needs.
