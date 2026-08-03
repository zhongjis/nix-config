# AI TOOLS MODULE

Profile-based, tool-agnostic configuration for Codex, OpenCode, Claude Code, Pi-family tools, and Factory.ai. Manages skills, plugins, agents, instructions, MCP servers, and permissions.

## PROFILE SYSTEM

`myHomeManager.aiProfile` (enum: `"work"` | `"personal"`) → `aiProfileHelpers` exposed via `_module.args`:
- `aiProfileHelpers.profile` — current profile string
- `aiProfileHelpers.isWork` / `aiProfileHelpers.isPersonal` — boolean guards

Set per host in `hosts/{name}/home.nix`. Used for filtering skills, instructions, MCP servers, and plugins.


## COMMANDS

Run from the repo root:

- `nh home switch .`
- `nix flake check`

## BOOTSTRAP AND MAINTENANCE

- Set `myHomeManager.aiProfile` in `hosts/{name}/home.nix` before enabling ai-tools; profile helpers and profile-filtered content depend on it
- Skills come from the `agent-skills` flake input through `lib.skillsFor`; maintain them in the sibling `agent-skills` repository. `common/instructions/*` files remain locally auto-discovered. Tool-specific instructions, MCP servers, and shared agents stay defined in their respective `default.nix` files
- For upstream/shared skill sync and update policy, follow the `skill-maintainer` workflow instead of inventing ad hoc local conventions here

## LSP OWNERSHIP

- `common/lsp.nix` owns the global AI-tool LSP server definitions and exports `commonLsp` via `_module.args`.
- Tool-specific adapters consume `commonLsp` directly: `opencode/lsp.nix` writes OpenCode settings, and `pi/lsp.nix` writes `~/.pi/agent/lsp.json`.
- Pi extension loading remains repo-managed by `pi-config/install.sh`, not `programs.pi.extensions` or `settings.json` packages.
- `pi-config/lsp.json` was removed. `.pi-lsp.json` in pi-config is preserved legacy/non-dreki state; dreki project overrides use `.pi/lsp.json`.
- Claude Code and Codex do not consume common LSP yet. Treat both as future integrations until projection + generated-config tests exist.

## STRUCTURE

```
ai-tools/
├── default.nix              # Imports common + tool modules, defines aiProfile option
├── profile-option.nix       # aiProfile enum + helpers
├── common/                  # Shared across all tools
│   ├── skills/              # Selects common profile skills from agent-skills
│   ├── instructions/        # Markdown instruction files
│   │   ├── general/         # All systems
│   │   ├── work/            # Work profile only
│   │   └── personal/        # Personal profile only
│   ├── mcp/                 # MCP server definitions
│   ├── agents/              # Agent configuration
│   └── lsp.nix              # Global LSP server source of truth exported as commonLsp
├── codex/                   # Codex CLI config (global config + shared skills)
├── opencode/                # OpenCode-specific
│   ├── plugins/             # oh-my-opencode plugins
│   ├── skills/              # OpenCode-only skills
│   ├── agents/              # Agent definitions
│   ├── instructions/        # OpenCode-only instructions
│   ├── permission.nix       # Runtime permission wildcards
│   ├── provider.nix         # LLM provider config
│   ├── formatters.nix       # Code formatters
│   └── lsp.nix              # OpenCode adapter from commonLsp to programs.opencode.settings.lsp
├── claude-code/             # Claude Code-specific settings, agents, and instructions
├── pi/                      # Pi-specific settings, instructions, and LSP adapter
└── factory/                 # Factory.ai-specific (skills only, via home.file symlinks)
```

## SKILL SELECTION

The `agent-skills` flake discovers canonical skill directories. Nix selects them at eval time:

```nix
inputs.agent-skills.lib.skillsFor {
  profile = aiProfileHelpers.profile;
  harness = "pi";
}
```

- **Canonical layout**: `skills/common-{general,work,personal}` and `skills/<harness>-{general,work,personal}`
- **Merge order**: common skills → harness-specific skills (harness overrides common on name collision)
- **Exposed via**: `_module.args.commonSkills`, merged into `programs.opencode.skills` / `programs.claude-code.skills` / `programs.pi.skills` / `home.file` (factory)

## SKILL CONVENTIONS

- Each skill: directory with `SKILL.md` + optional supporting files
- YAML frontmatter: `name`, `description`, optional `upstream`, optional `adaptedFrom`
- **`upstream` present** → single canonical sync source; can be updated via skill-maintainer. Must be a singular URL string, never a list.
- **`upstream` absent** → locally created; do not attempt upstream sync
- **`adaptedFrom` present** → informational lineage only (e.g., a previous upstream or manually merged source); not used for automated sync or update checks
- Locally authored shared skills must be vendor-neutral — see Genericize rules in skill-maintainer skill
- Default leaf contract is `SKILL.md`; do **not** add a skill-local `AGENTS.md` unless upstream tooling or generated reference packaging clearly requires it
- If a skill leaf keeps `AGENTS.md`, use it for navigation/compatibility only and keep contributor/build workflow in `README.md`

## OPENCODE PLUGIN SYSTEM

Plugins configured via `pluginLib` helpers in `opencode/plugins/`:

- `pluginLib.normalizePluginName` — extracts name from `@scope/plugin@version`, `github:user/repo@ref`, `file:///path`
- `pluginLib.mkOpenCodePluginList` — builds plugin list from generalPlugins + profile-filtered lists
- `pluginLib.hasPlugin` — conditional config based on plugin presence

**oh-my-opencode**: Nix attrsets → JSON generation. Profile overrides via `recursiveUpdate`. Plugins inject settings via `programs.opencode.ohMyOpenCode.settings`.

## MCP SERVERS

Defined in `common/mcp/default.nix`. General: nixos-docs, context7, mcp-k8s. Personal: flux-operator-mcp.

## ADDING NEW SKILLS

1. In the sibling `agent-skills` repository, create the skill under the appropriate common or harness-specific profile directory
2. Add `SKILL.md` with YAML frontmatter (`name`, `description`)
3. If from external source, add `upstream` field (singular canonical URL). If adapting from a prior source alongside a new canonical upstream, add `adaptedFrom` as a YAML list of informational-only lineage URLs.
4. Genericize vendor-specific content for local/shared skills; preserve intentional upstream/generated packaging when that structure is the source artifact
5. Run the agent-skills selector, Skills CLI, and flake checks; push the catalog commit
6. Update the `agent-skills` input here, run `nix flake check`, then apply with `nh home switch .`
For contributor-oriented build, validation, or generation steps inside a skill directory, document them in that skill's `README.md`, not here.
