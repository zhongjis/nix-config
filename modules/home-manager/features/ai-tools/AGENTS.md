# AI TOOLS MODULE

Profile-based, tool-agnostic configuration for Codex, OpenCode, Claude Code, Pi-family tools, and Factory.ai. Manages skills, plugins, agents, instructions, MCP servers, and permissions.

## PROFILE SYSTEM

`myHomeManager.aiProfile` (enum: `"work"` | `"personal"`) → `aiProfileHelpers` exposed via `_module.args`:
- `aiProfileHelpers.profile` — current profile string
- `aiProfileHelpers.isWork` / `aiProfileHelpers.isPersonal` — boolean guards

Set per host in `hosts/{name}/home.nix`. Used for filtering skills, instructions, MCP servers, and plugins.


## COMMANDS

Run from the repo root:

- `nh darwin switch .`
- `nh os switch .`
- `nix flake check`

## BOOTSTRAP AND MAINTENANCE

- Set `myHomeManager.aiProfile` in `hosts/{name}/home.nix` before enabling ai-tools; profile helpers and profile-filtered content depend on it
- Skills and `common/instructions/*` files are auto-discovered from the correct profile subtree; place them in the right directory and do not add manual registration. Tool-specific instructions, MCP servers, and shared agents stay defined in their respective `default.nix` files
- For upstream/shared skill sync and update policy, follow the `skill-maintainer` workflow instead of inventing ad hoc local conventions here
## STRUCTURE

```
ai-tools/
├── default.nix              # Imports common + tool modules, defines aiProfile option
├── profile-option.nix       # aiProfile enum + helpers
├── common/                  # Shared across all tools
│   ├── skills/              # Auto-discovered skill directories
│   │   ├── general/         # All systems (~35 skills)
│   │   ├── work/            # Work profile only
│   │   └── personal/        # Personal profile only
│   ├── instructions/        # Markdown instruction files
│   │   ├── general/         # All systems
│   │   ├── work/            # Work profile only
│   │   └── personal/        # Personal profile only
│   ├── mcp/                 # MCP server definitions
│   └── agents/              # Agent configuration
├── codex/                   # Codex CLI config (global config + shared skills)
├── opencode/                # OpenCode-specific
│   ├── plugins/             # oh-my-opencode plugins
│   ├── skills/              # OpenCode-only skills
│   ├── agents/              # Agent definitions
│   ├── instructions/        # OpenCode-only instructions
│   ├── permission.nix       # Runtime permission wildcards
│   ├── provider.nix         # LLM provider config
│   ├── formatters.nix       # Code formatters
│   └── lsp.nix              # LSP server config
├── claude-code/             # Claude Code-specific (skills, agents, instructions)
└── factory/                 # Factory.ai-specific (skills only, via home.file symlinks)
```

## SKILL AUTO-DISCOVERY

Skills are directories containing `SKILL.md`. Auto-discovered at Nix eval time:

```nix
discoverSkills = profileDir: let
  dirs = myLib.dirsIn profileDir;
  enabledDirs = lib.filterAttrs (name: _: !(lib.hasPrefix "disabled-" name)) dirs;
in lib.mapAttrs (name: _: profileDir + "/${name}") enabledDirs;
```

- **Disable a skill**: prefix directory with `disabled-` (e.g., `disabled-find-skills/`)
- **Merge order**: common skills → tool-specific skills (tool overrides common on name collision)
- **Exposed via**: `_module.args.commonSkills`, merged into `programs.opencode.skills` / `programs.claude-code.skills` / `home.file` (factory)

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

1. Create directory in appropriate location (general/work/personal, common or tool-specific)
2. Add `SKILL.md` with YAML frontmatter (`name`, `description`)
3. If from external source, add `upstream` field (singular canonical URL). If adapting from a prior source alongside a new canonical upstream, add `adaptedFrom` as a YAML list of informational-only lineage URLs.
4. Genericize vendor-specific content for local/shared skills; preserve intentional upstream/generated packaging when that structure is the source artifact
5. Apply from the repo root with `nh darwin switch .` or `nh os switch .`, then run `nix flake check` (auto-discovered, no registration needed)
For contributor-oriented build, validation, or generation steps inside a skill directory, document them in that skill's `README.md`, not here.
