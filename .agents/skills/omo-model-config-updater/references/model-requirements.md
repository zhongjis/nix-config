# OMO Model Requirements — Dynamic Lookup Guide

## How to Fetch Latest (ALWAYS DO THIS FIRST)

```bash
curl -fsSL https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/src/shared/model-requirements.ts
```

If fetch fails, use the Last-Known-Good Snapshot below as fallback.

## How to Read model-requirements.ts

The file defines **static fallback chains** per agent/category. OMO has NO runtime fallback — these chains are used only during config generation.

### Key Concepts

1. **Provider detection**: OMO checks which providers the user has configured
2. **Fallback chain**: For each agent/category, a prioritized list of `{ model, provider, tier? }` entries
3. **First match wins**: The first entry whose provider is available gets selected
4. **Tiers**: Optional quality level — `max`, `xhigh`, `high`, `medium`, `low` (affects model behavior/cost)

### Reading Pattern

```typescript
// Example structure in model-requirements.ts
agentName: [
  { model: "best-model", provider: "expensive-provider", tier: "max" },
  { model: "good-model", provider: "mid-provider", tier: "high" },
  { model: "fallback-model", provider: "free-provider" },
]
```

For a user with `gemini + copilot + opencode-zen`, walk each chain and pick the first entry where provider ∈ {google, github-copilot, opencode}.

### Agents to Configure

| Agent | Role | Notes |
|-------|------|-------|
| sisyphus | Primary orchestrator | Needs strongest reasoning model |
| oracle | Read-only consultant | Strong but expensive — use high tier |
| prometheus | Planning agent | Needs strong reasoning |
| metis | Pre-planning analysis | Needs strong reasoning |
| momus | Plan reviewer | Moderate tier sufficient |
| multimodal-looker | Vision/image tasks | Must support image input |
| librarian | External reference search | Low-stakes, prefer free models |
| explore | Codebase grep | Fast model preferred |
| atlas | General assistant | Low-stakes, prefer free models |

### Categories to Configure

| Category | Role | Notes |
|----------|------|-------|
| visual-engineering | Frontend/UI/design | Prefer models good at visual/creative |
| ultrabrain | Hard logic-heavy tasks | Strongest available model |
| deep | Deep problem solving | Strong model, moderate tier |
| artistry | Creative approaches | Creative/unconventional model |
| quick | Trivial single-file tasks | Cheapest model |
| unspecified-high | High effort catch-all | Strong model |
| unspecified-low | Low effort catch-all | Standard model |
| writing | Docs/prose/technical writing | Good at natural language |

## Last-Known-Good Snapshot (Fallback)

**Provider combination: gemini + copilot + opencode-zen**
**Snapshot date: February 2026**

> Use this ONLY if upstream fetch fails. Always prefer fresh data.

### Agents

| Agent | Model | Provider | Tier |
|-------|-------|----------|------|
| sisyphus | claude-opus-4.6 | github-copilot | max |
| oracle | gpt-5.2 | github-copilot | high |
| prometheus | claude-opus-4.6 | github-copilot | max |
| metis | claude-opus-4.6 | github-copilot | max |
| momus | gpt-5.2 | github-copilot | medium |
| multimodal-looker | gemini-3-flash-preview | google | — |
| librarian | glm-4.7 | opencode | — |
| explore | grok-code-fast-1 | github-copilot | — |
| atlas | kimi-k2.5-free | opencode | — |

### Categories

| Category | Model | Provider | Tier |
|----------|-------|----------|------|
| visual-engineering | gemini-3-pro-preview | google | — |
| ultrabrain | gpt-5.2-codex | github-copilot | xhigh |
| deep | gpt-5.2-codex | github-copilot | medium |
| artistry | gemini-3-pro-preview | google | high |
| quick | claude-haiku-4.5 | github-copilot | — |
| unspecified-high | claude-opus-4.6 | github-copilot | max |
| unspecified-low | claude-sonnet-4.5 | github-copilot | — |
| writing | gemini-3-flash-preview | google | — |

## Important Notes

- OMO has NO runtime model fallback (open issues #1420, #7602, #1114)
- If a model name from upstream doesn't match `opencode models` output, the model-requirements.ts may reference a model not yet available in your opencode version — skip it and use the next in chain
- Free-tier models (opencode/glm-4.7, opencode/kimi-k2.5-free) don't count against any quota
