# Provider Model Names — Naming Conventions & Pitfalls

## Dynamic Verification (MANDATORY)

**ALWAYS run `opencode models` before writing config.** The lists below are last-known-good snapshots and may be outdated. New models are added regularly.

```bash
# Get current available models
opencode models

# Look for specific provider
opencode models | grep "github-copilot"
opencode models | grep "google"
opencode models | grep "opencode"
```

If a model from upstream model-requirements.ts doesn't appear in `opencode models`, it's not available yet — skip it and use the next fallback.

## GitHub Copilot (`github-copilot/`)

### Naming Convention
- Use **dots** for version numbers: `claude-opus-4.6` NOT `claude-opus-4-6`
- Use **dashes** for word separation: `gpt-5.2-codex` NOT `gpt5.2codex`

### Available Models (as of last check)

| Model | Quota Multiplier | Use For |
|-------|-----------------|---------|
| `github-copilot/claude-haiku-4.5` | 0.33x | Quick/cheap tasks |
| `github-copilot/claude-sonnet-4.5` | 1x | Standard tasks |
| `github-copilot/claude-opus-4.6` | 3x | Complex reasoning |
| `github-copilot/gpt-5.2` | 1x | Standard tasks |
| `github-copilot/gpt-5.2-codex` | 3x | Hard logic/code tasks |
| `github-copilot/grok-code-fast-1` | — | Fast code search |

### Known Pitfalls

| Wrong | Correct | Issue |
|-------|---------|-------|
| `claude-opus-4-6` | `claude-opus-4.6` | Dashes vs dots in version |
| `claude-sonnet-4-5` | `claude-sonnet-4.5` | Dashes vs dots in version |
| `claude-haiku-4-5` | `claude-haiku-4.5` | Dashes vs dots in version |
| `gpt-5.3-codex` | `gpt-5.2-codex` | 5.3 doesn't exist on Copilot |

## Google / Antigravity Auth (`google/`)

### Naming Convention
- Preview models need `-preview` suffix
- Use **dashes** throughout: `gemini-3-flash-preview`

### Available Models

| Model | Context | Use For |
|-------|---------|---------|
| `google/gemini-3-flash-preview` | 1M | Fast multimodal, writing |
| `google/gemini-3-pro-preview` | 1M | Visual engineering, creative |
| `google/gemini-2.5-flash` | 1M | Legacy flash |
| `google/gemini-2.5-pro` | 1M | Legacy pro |

### Antigravity-Specific Models

These are defined in `antigravity-auth.nix` and route through antigravity OAuth:

| Model | Thinking Variants |
|-------|------------------|
| `antigravity-gemini-3-pro` | low, high |
| `antigravity-gemini-3-flash` | minimal, low, medium, high |
| `antigravity-claude-sonnet-4-5` | (none) |
| `antigravity-claude-sonnet-4-5-thinking` | low (8192), max (32768) |
| `antigravity-claude-opus-4-5-thinking` | low (8192), max (32768) |
| `antigravity-claude-opus-4-6-thinking` | low (8192), max (32768) |

> Note: Antigravity model names use **dashes** for versions (e.g., `4-5` not `4.5`) because they're identifiers, not Copilot model names.

### Known Pitfalls

| Wrong | Correct | Issue |
|-------|---------|-------|
| `gemini-3-flash` | `gemini-3-flash-preview` | Missing `-preview` suffix |
| `gemini-3-pro` | `gemini-3-pro-preview` | Missing `-preview` suffix |

## OpenCode Zen (`opencode/`)

### Naming Convention
- Simple names with version: `glm-4.7`, `kimi-k2.5-free`
- No `-free` suffix ambiguity: `glm-4.7` (NOT `glm-4.7-free`)

### Available Models

| Model | Context | Use For |
|-------|---------|---------|
| `opencode/glm-4.7` | 128K | Code tasks (librarian) |
| `opencode/kimi-k2.5-free` | 128K | Agentic reasoning (atlas) |

### Known Pitfalls

| Wrong | Correct | Issue |
|-------|---------|-------|
| `glm-4.7-free` | `glm-4.7` | `-free` suffix doesn't exist |
| `kimi-2.5` | `kimi-k2.5-free` | Missing `k` prefix and `-free` suffix |
