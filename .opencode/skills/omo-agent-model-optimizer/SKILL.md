---
name: omo-agent-model-optimizer
description: Runs the workflow for optimizing oh-my-opencode agent and category model settings in this project. Use when the user wants to optimize, review, recalibrate, or compare OMO model mappings, especially for work vs personal profiles, provider preferences, or questions like "what should my omo agent models be", "optimize my oh-my-opencode models", or "recommend better models for sisyphus, explore, librarian, or categories".
---

# OMO Agent Model Optimizer

Optimize oh-my-opencode model assignments for this repo by reconciling the user's target profile, provider scope, live model availability, and the latest upstream matching guidance.

This skill is for **recommendation and analysis**. It does not auto-edit Nix or JSON config unless the user separately asks for implementation.

## When this skill applies

Use this skill when the user wants to:

- optimize or review OMO agent or category model settings,
- compare current work vs personal model mappings,
- choose better models for agents like `sisyphus`, `oracle`, `explore`, or `librarian`,
- align local configuration with upstream oh-my-opencode model-matching guidance,
- evaluate provider tradeoffs such as GitHub Copilot vs OpenAI vs OpenCode Zen.

Do **not** use this skill for unrelated model questions, direct single-model substitutions with no optimization intent, or general LLM comparisons that are not about this project's OMO config.

## Core ideas

Follow these principles throughout the workflow:

1. **One profile at a time.** Optimize `work` or `personal` unless the user explicitly asks for both.
2. **Profile and provider mix change the answer materially.** Never assume the same recommendation applies across profiles.
3. **Upstream guidance is advisory, not absolute.** The latest guide informs the recommendation, but live model availability wins.
4. **Availability beats memory.** Use `opencode models` output as the source of truth for what the user can actually select.
5. **Distinguish hard constraints from preferences.** Separate "unavailable or incompatible" from "higher quality, cheaper, or faster if desired."
6. **Do not claim a universal best model.** Say what you recommend and why, based on the user's profile, providers, and preference axis.

## Project context

The primary configuration file for this repo is:

`modules/home-manager/features/ai-tools/opencode/plugins/oh-my-opencode.nix`

Important local facts:

- The repo has two profile override sections: `personalOverrides` and `workOverrides`.
- Model assignments are split across `agents.<name>.model` and `categories.<name>.model`.
- The generated runtime config is written to `~/.config/opencode/oh-my-opencode.jsonc`.
- Typical apply commands after edits are `nh darwin switch .` or `nh os switch .`, but this skill does not apply changes unless explicitly asked.

## Required workflow

Execute the workflow in this order.

### 1. Establish scope

First determine which profile is being optimized.

- If the user already said `work` or `personal`, use that.
- Otherwise, clarify with the user. Do not guess when the answer would materially change the recommendation.
- Optimize one profile at a time unless the user explicitly requests a comparison for both.

Then clarify provider scope.

- Ask which providers should be included or preferred if the user has not already made this clear.
- If helpful, frame it as: quality-first, cost-conscious, latency-first, or "use all available providers."
- Treat provider preference as required input when it changes the outcome.

### 2. Snapshot the current local config

Read the current OMO config before recommending anything.

Start with:

- `modules/home-manager/features/ai-tools/opencode/plugins/oh-my-opencode.nix`
- `~/.config/opencode/oh-my-opencode.jsonc` if it exists and is relevant

Extract the current agent and category assignments for the selected profile. Use that snapshot as the baseline for all comparisons.

### 3. Retrieve the latest upstream guidance

Fetch the latest model-matching guide from:

`https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/guide/agent-model-matching.md`

Treat it as a recommendation source, not guaranteed ground truth.

When using the guide:

- Prefer the latest fetched content over memory.
- Summarize the relevant fallback chains or recommended model families for the slots under review.
- Note if the upstream doc appears inconsistent with current local reality or live CLI output.
- If the fetch fails, say so explicitly and fall back to a local-config plus live-availability audit rather than inventing guidance.

### 4. Discover live model availability

Run `opencode models` against the provider set under consideration.

Use:

```bash
opencode models
opencode models <provider>
```

Examples:

```bash
opencode models github-copilot
opencode models openai
opencode models opencode
```

Rules:

- Use the CLI output as the source of truth for available model identifiers.
- Do not infer hidden ranking, aliasing, or fallback behavior from `opencode models` unless separately documented.
- If a provider returns nothing or errors, treat that as a live constraint and report it.

### 5. Compare current config vs upstream vs available models

Do a slot-by-slot comparison for the selected profile.

Check at least these dimensions:

1. **Current assignment** — what this repo currently uses.
2. **Upstream recommendation or fallback family** — what the latest guide suggests for that role.
3. **Live availability** — whether the exact model or a close valid alternative exists in the chosen provider scope.
4. **Provider fit** — whether the current or proposed model respects the user's stated provider preference.
5. **Role fit** — whether the model family matches the role. For example, utility slots such as `explore` and `librarian` favor speed and cost over maximum reasoning depth.

Be especially careful with these classes of slots:

- **Orchestrators and planners** such as `sisyphus`, `metis`, `prometheus`, and `atlas`.
- **Deep reasoning or review roles** such as `hephaestus`, `oracle`, and `momus`.
- **Utility runners** such as `explore` and `librarian`, where "upgrade to the smartest model" is usually the wrong move.
- **Categories** such as `visual-engineering`, `deep`, `quick`, and `unspecified-*`, where the recommendation is often about the model family rather than a single universal winner.

### 6. Produce the recommendation

Report the answer in two buckets:

#### Hard constraints

Use this section for cases where something is unavailable, incompatible with the chosen provider scope, or clearly conflicts with the upstream role shape.

Examples:

- Current model is not returned by `opencode models` for the chosen provider set.
- The user wants to avoid a provider that the current assignment depends on.
- A slot depends on a provider the user does not have configured.

#### Preferences

Use this section for subjective upgrades or tradeoffs.

Examples:

- Better quality if the user is willing to spend more.
- Better latency or quota preservation for utility slots.
- Better alignment with the upstream role family without being strictly required.

For each recommendation, include:

- the slot name,
- current model,
- proposed model,
- a short why,
- confidence level when the mapping is not exact.

When useful, include the Nix path to change, such as:

- `personalOverrides.agents.explore.model`
- `workOverrides.categories.quick.model`

## Output format

Prefer this structure:

### Scope

- Profile: `<work|personal>`
- Provider scope: `<providers considered>`
- Preference axis: `<quality|cost|latency|balanced>`

### Current snapshot

A concise summary of the current relevant slots.

### Hard constraints

Only include if any exist.

### Preferences

Primary recommendations and tradeoffs.

### Final recommendation

State the recommended mapping direction in plain language. If multiple valid paths remain, choose one primary path and explain why.

### Caveats

List uncertainty, missing providers, fetch failures, or places where upstream and live availability diverged.

## Guardrails

- Do not say "this is the best model" without qualification.
- Do not recommend models that were not verified via the upstream doc or live `opencode models` output.
- Do not assume `work` and `personal` should share the same mapping.
- Do not assume runtime fallback semantics beyond what the upstream guide actually documents.
- Do not mutate configuration files unless the user explicitly asks for implementation.
- If profile or provider scope is missing and changes the outcome materially, ask before continuing.

## If the user asks for implementation

If the user explicitly asks to apply the recommendation:

1. Update `modules/home-manager/features/ai-tools/opencode/plugins/oh-my-opencode.nix` only for the selected profile.
2. Keep the diff minimal.
3. Re-read the edited section to verify the intended assignments.
4. Run the relevant validation command if requested or appropriate.

Do not perform this implementation path unless the user asked for it.
