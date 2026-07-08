---
name: update-flake-inputs
description: Safe workflow for updating Nix flake input(s) in this repository. Use whenever the user asks to update, bump, refresh, pin, repin, or migrate any flake input or flake.lock entry — including nixpkgs, home-manager, Hyprland, Homebrew taps, overlays, private inputs, tool flakes, or groups of related inputs. Trigger even if the user only says “update inputs”, “bump nixpkgs”, “refresh flake.lock”, “update Hyprland”, or “bring this flake input to latest”. This skill prevents accidental broad lock churn, missed release-note migrations, broken follows/ABI compatibility, and false blame from pre-existing flake check failures.
disable-model-invocation: true
---

# Update Flake Inputs

Use this skill to update one or more Nix flake inputs deliberately. The goal is not just “run `nix flake update`”; it is to make a small, reviewable lock change, understand upstream changes, migrate configs when required, and verify the right outputs.

## Core principles

- Prefer scoped updates. `nix flake update` with no input names updates everything; use that only when the user explicitly asks for a broad update.
- Treat release notes as part of the update, not optional reading. Compare from the currently adopted version/revision to the target version/revision.
- Separate required migrations from optional tuning. Apply required config fixes; leave behavior-changing new options alone unless the user asks.
- Preserve `inputs.<name>.follows` relationships unless the release notes or build failures prove they need to change.
- Review `flake.lock` as a graph. A scoped root update can still move transitive inputs; expected transitive movement is OK, unrelated root churn is not.
- If verification fails, isolate the failure before blaming the update. Use targeted eval/builds and, when useful, compare against `HEAD` or the pre-update state.
- Keep this public repo clean: do not copy secrets, private repo content, work names, hostnames, or private release-note details into skill docs or commits.

## Workflow

### 1. Scope the request

Identify:

- requested input(s): exact names from `flake.nix` / `flake.lock`
- update type: latest, specific tag/branch/revision, or lock refresh
- related inputs that must move together, e.g. plugin ecosystems, overlays, or inputs with ABI compatibility requirements
- expected verification target: whole flake, host closure, package, dev shell, module eval, or a specific app

If scope is ambiguous, inspect first. Ask only when you cannot infer the input set safely.

### 2. Inspect current state

From repo root:

```bash
git status --short
nix flake metadata --no-write-lock-file
```

For machine-readable lock review:

```bash
nix flake metadata --json --no-write-lock-file
jq '.nodes.<input>.locked, .nodes.<input>.original' flake.lock
```

Use existing repo helper scripts when they match the requested scope:

```bash
scripts/update-hyprland-inputs.sh
scripts/update-nixos-inputs.sh
scripts/update-homebrew-inputs.sh
```

These scripts are examples of scoped update groups. Do not create a new helper script unless the same update group is likely to recur.

### 3. Research upstream changes

For each direct input and any tightly-coupled ecosystem input:

1. Find current adopted version/revision from `flake.nix`, `flake.lock`, or `nix flake metadata`.
2. Find target version/revision from official release notes, changelog, tags, or upstream docs.
3. Read every relevant release note between current and target, not just the newest release.
4. Extract:
   - breaking changes
   - config option removals/renames/moves
   - required command or module changes
   - lock-step compatibility notes, e.g. plugins matching compositor/toolkit versions
   - optional new features worth mentioning but not auto-enabling

Use official sources first. For GitHub projects without releases, use tags plus README/changelog and state that limitation.

### 4. Plan lock changes

Choose the narrowest command:

```bash
# Update one input
nix flake update <input>

# Update a related group
nix flake update <input-a> <input-b> <input-c>

# Add missing lock entries without changing existing pins
nix flake lock
```

Avoid:

```bash
nix flake update
```

unless the user explicitly asked for a broad flake refresh.

For inputs with `follows`, inspect both `flake.nix` and `flake.lock` before updating. Examples:

```nix
hyprland-plugins.inputs.hyprland.follows = "hyprland";
some-overlay.inputs.nixpkgs.follows = "nixpkgs";
```

Preserve follows when they express compatibility or deduplication. If removing or changing follows, explain why.

### 5. Apply update + required migrations

After the scoped lock update:

1. Review changed files:

   ```bash
   git diff --stat
   git diff -- flake.nix flake.lock
   git diff --name-only
   ```

2. Check lock movement:
   - direct input moved to expected target
   - transitive movement is expected for that ecosystem
   - unrelated root inputs did not move

3. Apply config migrations only when release notes require them.

Example migration discipline:

- Good: remove a config key that upstream says was removed.
- Good: move a setting from old namespace to new namespace when release notes say it moved.
- Not good: enable every new feature from release notes because it looks useful.
- Not good: change defaults with behavioral impact without user approval.

### 6. Verify in layers

Start narrow, then broaden:

```bash
# Lock metadata still evaluates
nix flake metadata --no-write-lock-file

# Eval-only whole flake
nix flake check --no-build

# Full check when feasible
nix flake check

# Targeted host closure
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Targeted package/app
eval_or_build_command_here
```

For Home Manager outputs:

```bash
nix eval .#homeConfigurations."<user>@<host>".config.<option.path>
```

For NixOS module values:

```bash
nix eval .#nixosConfigurations.<host>.config.<option.path>
```

If `nix flake check` fails:

- read the error path and option name
- run targeted evals for the updated input/config
- compare with pre-update `HEAD` when needed:

  ```bash
  nix flake check --no-build 'git+file:///absolute/repo/path?rev=<head-rev>'
  ```

Report a failure as unrelated only when you have evidence, not because it “looks unrelated”.

### 7. Final report

Use this structure:

```markdown
Updated:
- <input>: <old> → <new>

Config migrations:
- <file>: <required release-note migration>
- None required. Optional features left disabled: <list>

Lock/diff scope:
- Changed files: <list>
- Expected transitive inputs: <list>
- Unexpected movement: <none/list>

Verification:
- `<command>` → <result>
- `<command>` → <result>

Notes:
- <pre-existing failure or caveat, with evidence>
```

## Common patterns

### Single input bump

Use when the user says “update nixpkgs”, “bump home-manager”, or names one input.

1. Confirm exact input name in `flake.nix`.
2. Read upstream release/channel notes relevant to the jump.
3. Run `nix flake update <input>`.
4. Verify only that input and expected transitives moved.
5. Run targeted checks.

### Ecosystem bump

Use when inputs must stay compatible, e.g. compositor + plugins, language toolchain + overlays, or app + plugin flakes.

1. Identify root input and dependent inputs.
2. Preserve follows relationships.
3. Update the ecosystem as one scoped group.
4. Review release notes across all relevant components.
5. Apply only required config migrations.

### Lock refresh without version bump

Use `nix flake lock` when adding a new input or creating missing lock entries without changing existing pins.

### Broad refresh

Only when the user explicitly asks for all inputs to move.

1. State blast radius before running.
2. Expect many independent release-note reviews.
3. Split verification by input group.
4. Keep optional feature adoption separate from lock update.

## What to avoid

- Do not run broad `nix flake update` for a scoped request.
- Do not skip release notes for major, fast-moving, ABI-sensitive, or config-heavy inputs.
- Do not rely only on the latest patch release notes; inspect the full range from current adopted version to target.
- Do not silently remove or add `follows`.
- Do not commit generated/private details into this public repo.
- Do not call the work done if only the lock updated but required config migrations remain.
- Do not hide verification failures. Either fix them, prove they are pre-existing/unrelated, or ask for guidance.
