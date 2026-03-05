# Shell Strategy (Global)

**Context:** OpenCode has two shell execution modes with different capabilities:

| Mode | Tool | Interactive | Use Case |
|------|------|-------------|----------|
| **Bash** | `bash` tool | NO — no TTY, hangs on prompts | One-shot commands, scripts, quick operations |
| **PTY** | `pty_spawn` / `pty_write` / `pty_read` | YES — full TTY | Dev servers, watch modes, REPLs, long-running processes |

**Goal:** Use the right tool for the job. Default to non-interactive bash for speed; escalate to PTY only when interactivity is required.

## 1. Tool Selection

**DEFAULT: Use `bash` with non-interactive patterns.** It's faster, simpler, and sufficient for ~90% of shell work.

**Use PTY (`pty_spawn`) when:**
- Running dev servers or watch modes (`npm run dev`, `cargo watch`)
- Process needs to stay alive across multiple turns
- Interactive debugging sessions (e.g., `pudb`, `gdb`)
- TUI applications that require ongoing interaction
- You need to send Ctrl+C or other control sequences

**Use `bash` for everything else:**
- One-shot commands (`ls`, `git status`, `npm install`)
- Build commands (`nix build`, `cargo build`)
- Test runs (`pytest`, `npm test`)
- File operations, git operations, package management

## 2. Bash Tool: Non-Interactive Rules

The `bash` tool has **no TTY**. Commands that prompt for input WILL HANG. These rules are MANDATORY for all `bash` tool usage:

1. **Assume `CI=true`**: Act as if running in a headless CI/CD pipeline.
2. **Force & Yes**: Always supply non-interactive flags (`-y`, `--yes`, `--no-edit`, `-f`).
3. **No Pagers**: Use `--no-pager` or pipe through `cat`. Env vars `PAGER=cat` and `GIT_PAGER=cat` are auto-set.
4. **No Editors**: `vim`, `nano`, `emacs` cannot run in bash tool. Use `Read`/`Write`/`Edit` tools instead.
5. **Prefer Tools**: Use `Read`/`Write`/`Edit`/`Grep`/`Glob` over shell equivalents (`sed`, `echo`, `cat`, `find`, `grep`).

### Critical Patterns (Bash Tool)

| Tool | Non-Interactive Pattern |
|------|------------------------|
| **Git Log/Diff** | `git log --no-pager` / `git diff --no-pager` |
| **Git Commit** | `git commit -m "message"` (never bare `git commit`) |
| **Git Merge/Pull** | `git merge --no-edit` / `git pull --no-edit` |
| **Git Rebase** | `git rebase` (never `-i`) |
| **Git Add** | `git add .` or `git add <file>` (never `-p`) |
| **NPM** | `npm init -y` / `npm install --yes` |
| **Docker Run** | `docker run image` (never `-it`, use PTY for interactive containers) |
| **Python/Node** | `python -c "code"` or `python script.py` (never bare `python`/`node` REPL) |
| **RM/CP/MV** | `rm -f` / `cp -f` / `mv -f` |
| **Curl** | `curl -fsSL url` |
| **SSH/SCP** | `ssh -o BatchMode=yes -o StrictHostKeyChecking=no` |

### Handling Unknown Prompts

If a command might prompt, try these in order:
1. Check for `--yes`/`--force`/`--non-interactive` flag: `cmd --help 2>&1 | grep -i "force\|yes\|non-interactive"`
2. Pipe yes: `yes | ./script.sh`
3. Heredoc for known prompts: `./configure <<EOF ... EOF`
4. Timeout as last resort: `timeout 30 ./cmd`
5. Escalate to PTY if truly interactive behavior is needed

## 3. Environment Variables (Auto-Set for Bash)

These are pre-configured to prevent common hangs:

| Variable | Value | Purpose |
|----------|-------|---------|
| `CI` | `true` | General CI detection |
| `GIT_TERMINAL_PROMPT` | `0` | Block git auth prompts |
| `GIT_EDITOR` | `true` | Block git editor |
| `PAGER` / `GIT_PAGER` | `cat` | Disable pagers |
| `npm_config_yes` | `true` | NPM prompts |
| `PIP_NO_INPUT` | `1` | Pip prompts |
| `DEBIAN_FRONTEND` | `noninteractive` | Apt/dpkg prompts |

## 4. Behavioral Standards

1. **Process Continuity**: Never stop after tool output to "wait for instructions" unless the task is complete. Drive the workflow forward.
2. **Actionable Positive Constraints**: Frame rules as what TO DO, not what to avoid.
   - *Example:* Instead of "Don't use logging.getLogger()", use "ALWAYS USE: config.logging_config.get_logger()".
