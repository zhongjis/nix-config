# Nix-Config AI System

Context-aware AI system for managing the nix-config repository with NixOS, nix-darwin, and Home Manager configurations.

## Overview

This system provides specialized AI agents for managing your Nix configuration across multiple machines, with focus on:

- **Flake management** - Analyze, update, and migrate flake configurations
- **Module organization** - Create, validate, and refactor Nix modules
- **Host management** - Manage framework-16 (NixOS) and mac-m1-max (nix-darwin)
- **Package development** - Create and test custom Nix packages
- **Secret management** - Secure SOPS-encrypted secrets
- **Refactoring** - Migrate to flake-parts and improve organization

## Quick Start

### Basic Commands

```bash
# Analyze your flake
/flake-analyze

# Update flake inputs
/update-flake

# Switch to a host
/switch-host framework-16

# Create a new module
/new-module kubernetes nixos/features

# Validate everything
/validate-config --full
```

### Available Commands

| Command | Description |
|---------|-------------|
| `/flake-analyze` | Analyze flake structure and dependencies |
| `/update-flake` | Update all flake inputs |
| `/migrate-flake-parts` | Migrate to flake-parts module system |
| `/new-module <name> <category>` | Create new module |
| `/refactor-modules` | Analyze and refactor modules |
| `/switch-host <host>` | Switch to host configuration |
| `/build-package <name>` | Build package locally |
| `/edit-secret <file>` | Edit SOPS-encrypted secret |
| `/validate-config` | Run comprehensive validation |
| `/check-modules` | Validate module structure |

## System Architecture

### Agents

1. **Nix Orchestrator** - Main coordinator, routes requests to specialists
2. **Flake Analyzer** - Flake structure, dependencies, updates
3. **Module Organizer** - Module creation, validation, organization
4. **Host Manager** - Host configurations, system switching
5. **Package Builder** - Custom packages, overlays, testing
6. **Refactor Agent** - Structure analysis, flake-parts migration

### Context Files

Located in `context/`:
- **shared/** - Core Nix, flake-parts, SOPS-Nix knowledge
- **domain/** - Your specific flake structure and patterns
- **processes/** - Workflows for common tasks
- **standards/** - Quality criteria and validation rules

### Workflows

- `workflows/flake-update.md` - Update flake inputs
- `workflows/new-module.md` - Create new modules
- `workflows/secret-management.md` - Manage secrets
- `workflows/host-switch.md` - Switch system configurations
- `workflows/package-dev.md` - Develop packages
- `workflows/refactoring.md` - Migrate and refactor

## Project Structure

```
.opencode/
├── agent/
│   ├── nix-orchestrator.md          # Main orchestrator
│   └── subagents/
│       ├── flake-analyzer.md
│       ├── module-organizer.md
│       ├── host-manager.md
│       ├── package-builder.md
│       └── refactor-agent.md
├── context/
│   ├── shared/
│   │   ├── nix-core.md
│   │   ├── flake-parts.md
│   │   └── sops-nix.md
│   ├── domain/
│   │   ├── flake-structure.md
│   │   ├── target-structure.md
│   │   └── hosts.md
│   ├── processes/
│   │   ├── flake-update.md
│   │   ├── new-module.md
│   │   ├── secret-management.md
│   │   ├── host-switch.md
│   │   ├── package-dev.md
│   │   └── refactoring.md
│   └── standards/
│       ├── quality-criteria.md
│       ├── validation-rules.md
│       └── flake-parts-patterns.md
├── command/
│   ├── flake-analyze.md
│   ├── update-flake.md
│   ├── migrate-flake-parts.md
│   ├── new-module.md
│   ├── refactor-modules.md
│   ├── switch-host.md
│   ├── build-package.md
│   ├── edit-secret.md
│   ├── validate-config.md
│   └── check-modules.md
├── workflows/
│   ├── flake-update.md
│   ├── new-module.md
│   ├── secret-management.md
│   ├── host-switch.md
│   ├── package-dev.md
│   └── refactoring.md
└── README.md                         # This file
```

## Supported Hosts

| Host | OS | Architecture | Profile |
|------|-----|--------------|---------|
| **framework-16** | NixOS | x86_64-linux | Desktop + Gaming |
| **Zs-MacBook-Pro** | macOS | aarch64-darwin | Full macOS |
| **thinkpad-t480** | NixOS | x86_64-linux | (inactive) |

## Common Tasks

### Update Your Flake

```bash
/update-flake --validate --commit
```

### Add a New Module

```bash
/new-module my-feature nixos/features --options enable,setting
# Edit the created module
# Add to host configuration
```

### Switch to Framework-16

```bash
/switch-host framework-16 --dry-run  # Test first
/switch-host framework-16            # Apply
```

### Edit a Secret

```bash
/edit-secret ssh.yaml --view         # View
/edit-secret ssh.yaml                # Edit
/edit-secret ssh.yaml --switch       # Deploy
```

### Migrate to Flake-Parts

```bash
/migrate-flake-parts --dry-run       # Preview
/migrate-flake-parts --phase 1       # Start with infrastructure
# ... continue through phases
```

### Validate Everything

```bash
/validate-config --full
```

## Best Practices

1. **Always dry-run first** - Test before applying changes
2. **Validate after updates** - Run `/validate-config`
3. **Commit with context** - Document what changed
4. **Backup before major changes** - Keep working state
5. **Use secrets properly** - Never commit decrypted

## Documentation

- **Context Files**: See `context/` for detailed knowledge
- **Workflows**: See `workflows/` for step-by-step guides
- **Commands**: See `command/` for command documentation
- **Agents**: See `agent/` for agent capabilities

## Requirements

- Nix with flakes enabled
- nix-darwin (for macOS)
- Home Manager
- SOPS-Nix for secrets
- `nh` tool for system switching

## Troubleshooting

### Command not found

Ensure you're in the nix-config directory with the `.opencode/` folder.

### Validation fails

Run `/validate-config --full` to see all issues.

### Switch fails

Run `/switch-host <host> --dry-run` to diagnose.

### Secret editing fails

Ensure your age key is properly configured.

## Contributing

This system is designed for your personal use. To customize:

1. Edit context files in `context/` to add project-specific knowledge
2. Modify workflows in `workflows/` to match your processes
3. Add new commands in `command/` for common tasks
4. Extend agents in `agent/` for new capabilities

## License

This is a personal configuration system. See repository license.
