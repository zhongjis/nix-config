# AI Workflow and Skills

This file is the central guide for how this repo manages AI-agent workflow. It covers skills, profiles, tool-specific extensions, instructions, agents, MCP servers, plugins, and maintenance rules.

For execution rules and contributor guidance, see `AGENTS.md`.

> Public repo rule: keep work names, secrets, private hostnames, and private-repo content out of this tree. Put private workflow details in `nix-config-private`.

## Mental model

The module has three layers:

1. `common/` holds shared resources used across AI tools.
2. Tool directories (`opencode/`, `claude-code/`, `factory/`, `omp/`, `codex/`, `pi/`) add tool-specific wiring or extensions.
3. Profile directories (`general/`, `work/`, `personal/`) choose which resources apply to each host via `myHomeManager.aiProfile`.

Use the narrowest layer that fits: common when a skill should work everywhere, profile-specific when content belongs only to work or personal machines, and tool-specific only when the skill or config depends on one tool.

## Directory map

```text
ai-tools/
├── default.nix              # Imports common + tool modules; defines aiProfile
├── common/
│   ├── skills/              # Shared skills, auto-discovered by profile
│   │   ├── general/         # Available to all profiles
│   │   ├── work/            # Work profile only
│   │   └── personal/        # Personal profile only
│   ├── instructions/        # Shared instruction markdown, profile-filtered
│   ├── agents/              # Shared agent config
│   └── mcp/                 # Shared MCP server config
├── opencode/                # OpenCode config, plugins, agents, skills
├── claude-code/             # Claude Code config, rules, skills
├── factory/                 # Factory skill and instruction symlinks
├── omp/                     # OMP-specific config and skill exports
├── codex/                   # Codex config
└── pi/                      # Pi-family config and skill exports
```

## Profiles

Set `myHomeManager.aiProfile` in `hosts/{name}/home.nix`:

- `general/` resources apply to every profile.
- `work/` resources apply only when `aiProfile = "work"`.
- `personal/` resources apply only when `aiProfile = "personal"`.

The profile also filters skills, instructions, MCP servers, plugins, and tool-specific resources where supported.

## Skill layering

Skills are directories containing `SKILL.md`. Each skill may also include references, templates, scripts, or assets.

Auto-discovery rules:

- Directory names become skill names.
- Prefix a directory with `disabled-` to skip it.
- Common skills are discovered from `common/skills/{general,work,personal}`.
- Tool-specific skills are discovered from each tool's `skills/{general,work,personal}` directory.
- Tool-specific skills override common skills with the same name.

Prefer common skills. Use tool-specific skills only for tool-dependent behavior or intentional overrides.

## Development cycle (skills only)

Use skills as the workflow spine:

| Stage | Skill workflow |
| --- | --- |
| Shape unclear idea | `grilling` → `domain-modeling` |
| Preserve project language | `domain-modeling` updates domain terms; ADRs record decisions |
| Explore logic or state uncertainty | `prototype` for throwaway state/API/business-rule harnesses |
| Explore UI direction | `impeccable` for production UI shaping; `huashu-design` for hi-fi HTML variants, demos, decks, and animation |
| Turn conversation into spec | `to-spec` |
| Split spec into work | `to-tickets` |
| Diagnose bug | `diagnosing-bugs` |
| Build or fix test-first | `tdd` |
| Review code | `code-review`; use `multi-reviewer` only when a panel review is requested |
| Address PR feedback | `address-comments` |
| Maintain skill set | `skill-maintainer` for vendoring and sync; `skill-creator` for creating or changing skills; `writing-great-skills` as the quality rubric |
| Handoff long context | `handoff`; use `context-management` for long messy sessions |
| Clean docs after milestone | `neat-freak` |

Keep this cycle limited to skills. Configuration details belong in later sections.

## Skill placement

Choose the target by scope:

| Need | Location |
| --- | --- |
| Shared across tools and profiles | `common/skills/general/<skill>/` |
| Shared across tools, work only | `common/skills/work/<skill>/` |
| Shared across tools, personal only | `common/skills/personal/<skill>/` |
| Tool-specific behavior for all profiles | `<tool>/skills/general/<skill>/` |
| Tool-specific work behavior | `<tool>/skills/work/<skill>/` |
| Tool-specific personal behavior | `<tool>/skills/personal/<skill>/` |

Each `SKILL.md` must have frontmatter:

```yaml
---
name: skill-name
description: "When to use this skill and what it does."
---
```

External skills must also include a singular canonical upstream URL:

```yaml
upstream: "https://github.com/org/repo/tree/main/path/to/skill"
```

Use `adaptedFrom` only for informational lineage. Do not treat it as another sync source.

## Vendoring and updates

Use `skill-maintainer` for upstream skills. Do not invent one-off vendoring flows.

Rules:

- Ask where the skill belongs before installing if scope is unclear.
- Copy the whole skill directory, not only `SKILL.md`, unless you intentionally adapt it.
- Add or preserve `upstream` as the canonical sync source.
- Genericize shared skills so they are not tied to one AI vendor.
- Keep local edits small and documented in the changed skill.
- Prefer allowlists over bulk vendoring from large upstream repos.
- Run `nix flake check` after changes when possible.

For private or work-specific upstreams, vendor into the private repo or a `work/` profile path. Never copy private content into this public repo.

## Tool-specific wiring

Common skills feed the tool modules through `_module.args.commonSkills`. Tool modules then merge their own filtered local skills.

Current consumers:

- OpenCode merges `commonSkills` with `opencode/skills/*`.
- Claude Code merges `commonSkills` with `claude-code/skills/*`.
- Factory symlinks `commonSkills` plus `factory/skills/*` into `~/.factory/skills/`.
- OMP exposes `omp/skills/*` for OMP-specific use.
- Codex and Pi-family modules use shared configuration where supported, but not every resource type maps one-to-one across tools.

When a tool needs different behavior, add a tool-specific override with the same skill name. Otherwise, keep the skill in `common/skills/`.

## Instructions, agents, MCP, and plugins

Skills are only one part of the workflow.

- `common/instructions/` holds shared instruction markdown filtered by profile.
- Tool-specific `instructions/` directories add local rules for one tool.
- `common/agents/` and tool-specific `agents/` hold agent definitions.
- `common/mcp/` defines shared MCP servers; profile-specific MCP belongs there when it should follow the same profile system.
- `opencode/plugins/` manages OpenCode plugins through Nix-generated configuration.

Use the same placement rule as skills: common first, profile-specific when needed, tool-specific only when required.

## Applying changes

From repo root:

```bash
nh home switch .
nix flake check
```

Home Manager-owned changes, including `programs.pi` and AI tool settings, require `nh home switch .`. Use `nh os switch .` or `nh darwin switch .` only for system-level changes.
