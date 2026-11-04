# Issues

Popup issue tracker for Jira Data Center and Linear (experimental). Presentation
and icons adapted from `mrolafsson/herdr-linear`; its MIT license is in `LICENSE`.
No backend binary or login helper is required.

## Configure

Opened with nothing configured, the popup shows **Connect Jira**: enter the Jira
base URL, for example `https://jira.example.com` (include a context path if
applicable), and press **Connect**. **Advanced** holds the My issues JQL and the
token command, prefilled with their defaults. Connect runs the command with
`zsh -c`, checks Jira's `/rest/api/2/myself` and loads My issues. "or connect
Linear (experimental)" asks for Linear's token command instead. Afterwards the
settings (both providers) are behind the gear beside the tabs, or `⌃,`.
Only configured providers are shown; with both, the provider badge (or `⌃T`)
switches, and the last provider is remembered.

Default commands are `printenv JIRA_TOKEN` and `printenv LINEAR_API_KEY`.
Export these in `~/.zshenv`, not only an interactive shell configuration.
Command output is trimmed and must be one nonempty line. The command is saved
in the mod's localStorage; the token is kept in memory only. Do not put a literal
token in the command. Saving settings or switching provider creates a new client.
Jira uses a Bearer PAT; Linear uses its personal API key without a Bearer prefix.
Network/TLS errors are displayed without a curl fallback.

Settings, recent tickets and the last My issues list (shown at once on the next
opening while a fresh one loads) are local runtime data in the mod's
localStorage, not Nix configuration. Use the popup to change them.

## Use

Laid out as herdr-linear's popup:

- One field filters the list (every word must match key, title, status, project
  or type). A whole key such as `TEAM-123` is also looked up beyond your issues
  and shown under "Not in your issues"; Enter opens it.
- Tabs: **My issues**, grouped by status (started, review first; to do; backlog;
  done), and **Recent** (up to 50 tickets opened here, newest first). `←` `→`
  switch tabs while the field is empty.
- Rows: status icon, key, title, then project and (Jira) issue type, and
  priority. `↑` `↓` choose, Enter opens, a click chooses and a second opens.
  `⌃O` opens the chosen issue in the browser, `⌃R` refreshes.
- States: a skeleton while the first list loads, the request's own error with
  Retry and Settings, and an empty-state hint.
- An issue shows status, key, assignee, priority, project/type, labels, links,
  description and comments. Jira wiki markup is shown as Markdown (headings,
  bold, monospace, code, links, lists, tables); Linear's is Markdown already.
- On an issue: `c` changes status (the provider's transitions; ↑ ↓ and Enter or
  1–9), `a` writes a comment (sent exactly as typed; `⌘↵` sends), `o` opens it
  in the browser, `y` copies its key, `b` its link, `r` reloads. `esc` leaves a
  menu or the comment, then the issue, then closes the popup. Every key is
  also a click along the bottom.
- `herdr-app do issues.<command>`: `escape`, `next`/`prev` (tabs), `reload`.
  Bind `escape` to `issues.escape` under `mod:issues` in keys.json if the app
  closes the popup before the mod sees Esc.

Comments and status changes write to the selected provider. There is no create
issue, worktree, agent, or start-work action.

## Integration

Publishes `issues.refs = {jiraHost, projectKeys, linear}` in shared state.
Project keys come from Jira My issues and `project in (...)` clauses in saved JQL.
Other mods can set `issues.open = {provider: "jira", key: "TEAM-123", at: Date.now()}`
then run `mod.open` with `{name: "issues"}`. The popup consumes newer requests
on opening, and while open (just after the frame that sees them); the handled
timestamp is persisted locally.

## Checks

From the repository root:

```sh
herdr-app check modules/home-manager/services/herdr-app/mods/issues
node --test modules/home-manager/services/herdr-app/mods/issues/tests/*.test.js
```

The Node check covers normalization, token output validation, project keys,
status grouping, Jira markup conversion, error messages and dry
comment/transition request payloads. It never writes to a real tracker.
For live QA, connect Jira, inspect My issues, open a ticket and inspect its
comments; do not send comments or change status during read-only verification.
Linear is experimental and requires separate live verification with a Linear key.
