# Shell Non-Interactive Strategy (Global)

**Context:** OpenCode's shell environment is strictly **non-interactive**. It lacks a TTY/PTY; any command waiting for input will hang.

**Goal:** Eliminate "human-in-the-loop" dependency during task execution.

## 1. Core Mandates
1. **Assume `CI=true`**: Act as if running in a headless CI/CD pipeline.
2. **No Editors/Pagers**: `vim`, `nano`, `less`, `more`, `man` are BANNED.
3. **Force & Yes**: Always preemptively supply "yes" or "force" flags.
4. **Use Tools**: Prefer `Read`/`Write`/`Edit` tools over shell manipulation (`sed`, `echo`, `cat`).
5. **No Interactive Modes**: Never use `-i` or `-p` flags that require user input.

## 2. Cognitive & Behavioral Standards
To match high-agency autonomous capabilities, enforce these patterns:

1. **Process Continuity (Turn-Taking)**: Never stop after tool output to "wait for instructions" unless complete. Drive the workflow.
2. **Explicit Action Framing**: Use **Actionable Positive Constraints**. Frame instructions as "Actionable Positive Constraints" to reduce hallucination.
   - *Example:* Instead of "Don't use logging.getLogger()", use "ALWAYS USE: config.logging_config.get_logger()".
3. **Context Hierarchy**: Rules in this file override general knowledge. If instructions conflict, cite this authority: "Per shell_strategy.md...".
4. **Environment Rigor**: Assume a headless environment where any prompt = failure.

## 3. Environment Variables (Auto-Set)
| Variable | Value | Purpose |
|----------|-------|---------|
| `CI` | `true` | General CI detection |
| `GIT_TERMINAL_PROMPT` | `0` | Git auth prompts |
| `GIT_EDITOR` | `true` | Block git editor |
| `PAGER` / `GIT_PAGER` | `cat` | Disable pagers |
| `npm_config_yes` | `true` | NPM prompts |
| `PIP_NO_INPUT` | `1` | Pip prompts |
| `DEBIAN_FRONTEND` | `noninteractive` | Apt/dpkg prompts |

## 4. Top 10 Critical Patterns
| Tool | GOOD (Non-Interactive) |
|------|------------------------|
| **NPM** | `npm init -y` / `npm install --yes` |
| **Git Commit** | `git commit -m "message"` |
| **Git Pull** | `git pull --no-edit` |
| **Git Rebase** | `git rebase` (standard, no `-i`) |
| **Files (RM)** | `rm -f file` |
| **Docker** | `docker run image` (no `-it`) |
| **Python** | `python -c "code"` or `python script.py` |
| **Node** | `node -e "code"` or `node script.js` |
| **Curl** | `curl -fsSL url` |
| **Banned** | Avoid `vim`, `less`, `man`, `git add -p` |

## 5. Handling Prompts & Best Practices
- **The "Yes" Pipe**: `yes | ./script.sh`
- **Heredoc**: `./configure <<EOF ... EOF`
- **Timeout**: `timeout 30 ./cmd` (last resort)
- **Check Help**: `cmd --help | grep -i "force\|yes\|non-interactive"`

---

## Appendix: Full Command Reference

### Package Managers
| Tool | Interactive (BAD) | Non-Interactive (GOOD) |
|------|-------------------|------------------------|
| **NPM** | `npm init` | `npm init -y` |
| **NPM** | `npm install` | `npm install --yes` |
| **Yarn** | `yarn install` | `yarn install --non-interactive` |
| **PNPM** | `pnpm install` | `pnpm install --reporter=silent` |
| **Bun** | `bun init` | `bun init -y` |
| **APT** | `apt-get install pkg` | `apt-get install -y pkg` |
| **APT** | `apt-get upgrade` | `apt-get upgrade -y` |
| **PIP** | `pip install pkg` | `pip install --no-input pkg` |
| **Homebrew** | `brew install pkg` | `HOMEBREW_NO_AUTO_UPDATE=1 brew install pkg` |

### Git Operations
| Action | Interactive (BAD) | Non-Interactive (GOOD) |
|--------|-------------------|------------------------|
| **Commit** | `git commit` | `git commit -m "msg"` |
| **Merge** | `git merge branch` | `git merge --no-edit branch` |
| **Pull** | `git pull` | `git pull --no-edit` |
| **Rebase** | `git rebase -i` | `git rebase` (non-interactive) |
| **Add** | `git add -p` | `git add .` or `git add <file>` |
| **Stash** | `git stash pop` (conflicts) | `git stash pop` or handle manually |
| **Log** | `git log` (pager) | `git log --no-pager` or `git log -n 10` |
| **Diff** | `git diff` (pager) | `git diff --no-pager` or `git --no-pager diff` |

### System & Files
| Tool | Interactive (BAD) | Non-Interactive (GOOD) |
|------|-------------------|------------------------|
| **RM** | `rm file` (prompts) | `rm -f file` |
| **RM** | `rm -i file` | `rm -f file` |
| **CP** | `cp -i a b` | `cp -f a b` |
| **MV** | `mv -i a b` | `mv -f a b` |
| **Unzip** | `unzip file.zip` | `unzip -o file.zip` |
| **Tar** | `tar xf file.tar` | `tar xf file.tar` (usually safe) |
| **SSH** | `ssh host` | `ssh -o BatchMode=yes -o StrictHostKeyChecking=no host` |
| **SCP** | `scp file host:` | `scp -o BatchMode=yes file host:` |
| **Curl** | `curl url` | `curl -fsSL url` |
| **Wget** | `wget url` | `wget -q url` |

### Docker
| Action | Interactive (BAD) | Non-Interactive (GOOD) |
|--------|-------------------|------------------------|
| **Run** | `docker run -it image` | `docker run image` |
| **Exec** | `docker exec -it container bash` | `docker exec container cmd` |
| **Build** | `docker build .` | `docker build --progress=plain .` |
| **Compose** | `docker-compose up` | `docker-compose up -d` |

### Python/Node REPLs
| Tool | Interactive (BAD) | Non-Interactive (GOOD) |
|------|-------------------|------------------------|
| **Python** | `python` | `python -c "code"` or `python script.py` |
| **Node** | `node` | `node -e "code"` or `node script.js` |
| **IPython** | `ipython` | Never use - always `python -c` |

### General Instruction Patterns (Beyond Shell)
| Goal | Negative Constraint (BAD) | Positive Constraint (GOOD) |
|------|---------------------------|----------------------------|
| **Logging** | `Do not use logging.getLogger()` | `ALWAYS USE: config.logging_config.get_logger()` |
| **Repo Scope** | `Don't create CLI code here` | `USE THIS REPO FOR: API backend only` |
