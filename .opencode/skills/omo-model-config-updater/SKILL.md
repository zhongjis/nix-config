---
name: omo-model-config-updater
description: "(opencode-project - Skill) Update oh-my-opencode (OMO) model assignments in this Nix config repository. Use when changing model assignments for agents or categories in personalOverrides or workOverrides, adding new models to antigravity-auth.nix, updating models after OMO upstream changes, optimizing model choices for rate limits or quota, or when the user says 'update omo models', 'change model config', 'fix model names', 'add antigravity model'. Triggers on requests involving oh-my-opencode.nix, antigravity-auth.nix, model assignments, provider models, or OMO configuration."
---

# OMO Model Config Updater

Update oh-my-opencode model assignments in this nix-config repository. Handles personalOverrides, workOverrides, and antigravity-auth model definitions.

## Workflow

### Step 1: Fetch Latest Upstream Recommendations (MANDATORY)

**ALWAYS fetch the latest model-requirements.ts before making changes.** Do NOT rely solely on the static snapshot in `references/model-requirements.md` — it may be outdated.

```bash
curl -fsSL https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/src/shared/model-requirements.ts
```

Parse the file to extract the fallback chain for the user's provider combination. See `references/model-requirements.md` for how to read the file and the last-known-good snapshot as fallback if fetch fails.

### Step 2: Identify User's Provider Combination

Determine which providers the user has by checking `oh-my-opencode.nix` or asking. Common combinations:

| Providers | Search Key in model-requirements.ts |
|-----------|-------------------------------------|
| gemini + copilot + opencode-zen | Look for chains containing google, github-copilot, opencode providers |
| copilot only | Look for github-copilot-only chains |
| gemini only | Look for google-only chains |

### Step 3: Verify Model Names (MANDATORY)

```bash
opencode models
```

Cross-reference every model name against this output. See `references/provider-models.md` for naming conventions and common pitfalls.

**Critical naming rules:**
- GitHub Copilot: dots for versions (`claude-opus-4.6` NOT `claude-opus-4-6`)
- Google: `-preview` suffix required (`gemini-3-flash-preview` NOT `gemini-3-flash`)
- OpenCode Zen: exact names only (`glm-4.7` NOT `glm-4.7-free`)
- Antigravity: dashes for versions (`antigravity-claude-opus-4-6-thinking`)

### Step 4: Edit Configuration

See `references/nix-config-structure.md` for file locations and Nix patterns.

**Files to edit:**

| File | When |
|------|------|
| `modules/home-manager/features/ai-tools/opencode/plugins/oh-my-opencode.nix` | Changing agent/category model assignments |
| `modules/home-manager/features/ai-tools/opencode/plugins/antigravity-auth.nix` | Adding/updating antigravity OAuth models |

**Constraints:**
- NEVER modify `workOverrides` unless explicitly asked — only touch `personalOverrides` by default
- Profile selection (`aiProfileHelpers.isWork`) determines which override applies at runtime

### Step 5: Verify

```bash
nix flake check --no-build
```

Must exit 0. If it fails, fix Nix syntax errors before proceeding.

### Step 6: Update Antigravity Models (if needed)

When upstream adds new models, check: `https://github.com/NoeFabris/opencode-antigravity-auth#models`

Add new model definitions to `antigravity-auth.nix` following the existing pattern. See `references/nix-config-structure.md` for the exact Nix attribute set structure.

## Quota Optimization

### GitHub Copilot (Pro plan: 1,500 premium requests/month)

| Model | Multiplier | Strategy |
|-------|-----------|----------|
| claude-haiku-4.5 | 0.33x | Use for quick/trivial tasks |
| claude-sonnet-4.5, gpt-5.2 | 1x | Standard tasks |
| claude-opus-4.6, gpt-5.2-codex | 3x | Reserve for critical reasoning |

### Antigravity Rate Limit Mitigation

- Multi-account rotation with `account_selection_strategy: "round-robin"`
- `pid_offset_enabled: true` for parallel agent sessions
- `scheduling_mode: "balance"` to spread load across accounts

### Free-Tier Models (OpenCode Zen)

Use `opencode/glm-4.7` and `opencode/kimi-k2.5-free` for low-stakes agents (librarian, atlas, explore) to save quota.

## References

- `references/model-requirements.md` — How to read upstream model-requirements.ts + last-known-good snapshot
- `references/provider-models.md` — Model naming conventions, available models, and common pitfalls
- `references/nix-config-structure.md` — Nix file locations, attribute patterns, and profile system
