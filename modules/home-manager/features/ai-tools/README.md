# AI Tools Module Architecture

This module organizes configuration for AI-assisted coding tools (OpenCode, Claude Code) and their shared resources (skills, MCP servers, instructions) using a **profile-based architecture** that supports multiple environments (work, personal).

## Module Hierarchy

The structure follows a layered approach to maximize reuse while allowing tool-specific and profile-specific overrides.

```text
ai-tools/
├── default.nix             # Root entry point, imports all categories
├── profile-option/         # Profile configuration module
│   └── default.nix         # Defines myHomeManager.aiProfile option (work|personal)
├── general/                # Resources shared by ALL AI tools and profiles
│   ├── default.nix         # Exports skills and mcp
│   ├── skills/             # 22 general-prefixed skill definitions
│   ├── mcp/                # MCP server configurations
│   ├── instructions/       # Shared markdown system prompts (nix-environment.md)
│   └── oh-my-opencode/     # oh-my-opencode configuration files
│       ├── general-oh-my-opencode-gemini.jsonc    # Shared config
│       ├── work-oh-my-opencode.jsonc             # Work profile config
│       └── personal-oh-my-opencode.jsonc         # Personal profile config
├── opencode/               # OpenCode-specific configuration
│   ├── default.nix         # Main OpenCode config with profile-based filtering
│   ├── instructions/       # OpenCode-specific markdown (shell-strategy.md)
│   ├── agents/             # Custom OpenCode agent instructions
│   ├── formatters.nix      # Formatter configurations
│   ├── permission.nix      # Permission settings
│   ├── provider.nix        # Provider settings
│   ├── lsp.nix             # LSP settings
│   ├── plugins/            # OpenCode-specific plugins (oh-my-opencode routing)
│   └── plugins/oh-my-opencode/default.nix
└── claude-code/            # Claude Code-specific configuration
    ├── default.nix         # Main Claude Code config with Nix-time filtering
    ├── instructions/       # (Subdirectory for future use)
    ├── agents/             # (Subdirectory for future use)
    └── skills/             # (Subdirectory for future use)
```

## Import Relationships

### Visual Overview

```mermaid
graph TD
    Root[ai-tools/default.nix] --> ProfileOpt[profile-option/default.nix]
    Root --> General[general/default.nix]
    Root --> Opencode[opencode/default.nix]
    Root --> ClaudeCode[claude-code/default.nix]

    General --> Skills[general/skills/ - 22 general-* skills]
    General --> MCP[general/mcp/]
    General --> Instructions[general/instructions/]
    General --> OhMyOpencode["general/oh-my-opencode/<br/>profiles: general-*, work-*, personal-*"]
    
    Opencode -.->|profile-based<br/>filtering| General
    Opencode --> OpencodeInst[opencode/instructions/]
    
    ClaudeCode -.->|Nix-time filtering| General
    ClaudeCode --> ClaudeCodeInst[claude-code/instructions/]
```

### Architecture Overview

**Profile-Based Organization**:
- The `profile-option/` module defines `myHomeManager.aiProfile` (enum: "work" | "personal")
- Each host sets its profile: `hosts/mac-m1-max/home.nix` → `aiProfile = "work"`, `hosts/framework-16/home.nix` → `aiProfile = "personal"`
- Resources are prefixed to indicate scope: `general-*`, `work-*`, `personal-*`

**Tool-Specific Filtering**:
- **OpenCode**: Uses runtime filtering with wildcard `permission.skill` patterns (e.g., `"work-*" = "allow"`)
- **Claude Code**: Uses Nix-time filtering with `lib.filterAttrs` and `lib.hasPrefix` to include/exclude skills at configuration time

**Shared Resources**:
- `general/` directory contains resources available to all profiles and tools
- 22 general-prefixed skills provide universal functionality
- oh-my-opencode configurations in `general/oh-my-opencode/` support all profiles

## Import Conventions

To maintain a clean and predictable structure, follow these path conventions:

### 1. Parent to Child (Downwards)
Use relative paths starting with `./`. This is the standard for importing sub-modules or local files.
```nix
# modules/home-manager/features/ai-tools/default.nix
imports = [
  ./profile-option
  ./general
  ./opencode
  ./claude-code
];
```

### 2. Child to Sibling (Sideways)
Use `../` to ascend to the parent directory and then descend into the sibling. This is common when tool-specific modules import shared resources.
```nix
# modules/home-manager/features/ai-tools/opencode/default.nix
imports = [
  ../general         # Access shared resources
  ./plugins          # Local tool-specific plugins
];
```

### 3. Referencing Assets (Markdown/Scripts)
When referencing files (like markdown instructions) that are not Nix modules, use string interpolation with the relative path. This ensures the files are correctly added to the Nix store.
```nix
# modules/home-manager/features/ai-tools/opencode/default.nix
settings.instructions = [
  "${./instructions/shell-strategy.md}"
  "${../general/instructions/nix-environment.md}"
];
```

## Naming Conventions

### Skill and File Prefixes
Resources follow a consistent prefix pattern to indicate their scope:

- **`general-*`**: Available to all profiles and tools (e.g., `general-agent-browser`, `general-nix`, `general-typescript`)
- **`work-*`**: Available only when `aiProfile = "work"` (reserved for future profile-specific skills)
- **`personal-*`**: Available only when `aiProfile = "personal"` (reserved for future profile-specific skills)

### Configuration Files
oh-my-opencode configurations follow the pattern `<profile>-oh-my-opencode<-variant>.jsonc`:

```
general/oh-my-opencode/
├── general-oh-my-opencode-gemini.jsonc      # Shared config variant
├── work-oh-my-opencode.jsonc                # Work profile config
└── personal-oh-my-opencode.jsonc            # Personal profile config
```

## Profile-Based Filtering

### OpenCode (Runtime Filtering)
OpenCode uses wildcard patterns in `settings.permission.skill` for runtime filtering:

```nix
# All profiles always get general-* skills
permission.skill = {
  "general-*" = "allow";
}
# Work profile additionally gets work-* skills
// lib.optionalAttrs aiProfileHelpers.isWork {
  "work-*" = "allow";
}
// lib.optionalAttrs aiProfileHelpers.isPersonal {
  "personal-*" = "allow";
};
```

**How it works**: At runtime, OpenCode checks each skill name against these patterns and allows/denies access accordingly.

### Claude Code (Nix-time Filtering)
Claude Code uses `lib.filterAttrs` and `lib.hasPrefix` for filtering at configuration evaluation time:

```nix
let
  allSkills = (import ../general/skills {inherit pkgs lib;}).programs.claude-code.skills;
  
  filteredSkills = lib.filterAttrs (name: _:
    lib.hasPrefix "general-" name
    || (aiProfileHelpers.isWork && lib.hasPrefix "work-" name)
    || (aiProfileHelpers.isPersonal && lib.hasPrefix "personal-" name)
  ) allSkills;
in {
  programs.claude-code.skills = filteredSkills;
}
```

**How it works**: The skills attribute set is evaluated at Nix time, producing a final configuration that only includes the appropriate skills. This happens once during `nix flake check` or build, not at runtime.

## Adding Resources by Profile

### Adding a New General Skill
1. Create a new directory in `general/skills/` with prefix `general-<name>` (e.g., `general-my-tool`)
2. Add to `general/skills/default.nix` with the same name as the directory
3. Available to both OpenCode and Claude Code on all profiles

### Adding a Work-Specific Skill
1. Create a new directory in `general/skills/` with prefix `work-<name>` (e.g., `work-my-tool`)
2. Add to `general/skills/default.nix` with the same name as the directory
3. Will only be available when `aiProfile = "work"`
4. Automatically filtered by both OpenCode (runtime) and Claude Code (Nix-time)

### Adding a Tool-Specific Instruction
- For **shared instructions** (both tools): Place in `general/instructions/`
- For **OpenCode only**: Place in `opencode/instructions/`
- For **Claude Code only**: Place in `claude-code/instructions/` (not yet used)

### Managing oh-my-opencode Configurations
- **General (Shared)**: `general/oh-my-opencode/general-oh-my-opencode-gemini.jsonc`
- **Work profile**: `general/oh-my-opencode/work-oh-my-opencode.jsonc` (routed by host: mac-m1-max)
- **Personal profile**: `general/oh-my-opencode/personal-oh-my-opencode.jsonc` (routed by host: framework-16)

The `opencode/plugins/oh-my-opencode/default.nix` module implements the routing logic based on `currentSystemName`.
