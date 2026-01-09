# System Architecture

Technical architecture of the Nix-Config AI System.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Nix Orchestrator Agent                        │
│                    (agent/nix-orchestrator.md)                   │
├─────────────────────────────────────────────────────────────────┤
│  • Request analysis and routing                                  │
│  • Workflow orchestration                                        │
│  • Context allocation management                                 │
│  • Error handling and recovery                                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
┌──────────────────┐ ┌───────────────┐ ┌──────────────────┐
│  Flake Analyzer  │ │Module Organizer│ │   Host Manager   │
│  (subagent)      │ │   (subagent)   │ │    (subagent)    │
├──────────────────┤ ├───────────────┤ ├──────────────────┤
│ • Flake analysis │ │ • Module CRUD  │ │ • Host configs   │
│ • Dependency mgmt│ │ • Validation   │ │ • System switch  │
│ • Updates        │ │ • Organization │ │ • Hardware       │
│ • Migration      │ │ • Imports      │ │ • Profiles       │
└──────────────────┘ └───────────────┘ └──────────────────┘
          │                 │                 │
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
┌──────────────────┐ ┌───────────────┐ ┌──────────────────┐
│  Package Builder │ │Refactor Agent │ │   (More agents   │
│    (subagent)    │ │   (subagent)  │ │    as needed)    │
├──────────────────┤ ├───────────────┤ └──────────────────┘
│ • Package dev    │ │ • Analysis    │
│ • Overlays       │ │ • Migration   │
│ • Testing        │ │ • Consolidation│
│ • Integration    │ │ • Quality     │
└──────────────────┘ └───────────────┘
```

## Agent Responsibilities

### Nix Orchestrator

**Purpose**: Central coordinator for all requests

**Responsibilities**:
- Analyze incoming requests
- Route to appropriate subagents
- Coordinate multi-agent workflows
- Allocate context levels (1/2/3)
- Handle errors and recovery

**Context Level Allocation**:
- Level 1 (80%): Subagent works alone
- Level 2 (20%): Subagent gets filtered context
- Level 3 (Rare): Full context for critical ops

### Flake Analyzer

**Purpose**: All flake-related operations

**Responsibilities**:
- Analyze flake.nix structure
- Manage inputs and dependencies
- Validate flake syntax and evaluation
- Configure Cachix binary caches
- Design flake-parts migration
- Generate analysis reports

### Module Organizer

**Purpose**: Module creation and management

**Responsibilities**:
- Create new module scaffolds
- Validate module structure and imports
- Organize modules into categories
- Ensure consistency with patterns
- Detect circular dependencies

### Host Manager

**Purpose**: Host-specific configuration management

**Responsibilities**:
- Manage framework-16 (NixOS)
- Manage mac-m1-max (nix-darwin)
- Handle Home Manager profiles
- System switching with nh tool
- Hardware detection and configuration
- Secret management integration

### Package Builder

**Purpose**: Custom package development

**Responsibilities**:
- Create new Nix packages
- Manage package overlays
- Test packages locally
- Cross-platform testing
- Integrate with flake outputs

### Refactor Agent

**Purpose**: Code organization and migration

**Responsibilities**:
- Analyze current structure
- Plan refactoring approaches
- Migrate to flake-parts
- Consolidate duplicate patterns
- Improve module organization
- Validate refactoring results

## Context Structure

### Shared Context

**Purpose**: Core knowledge used by all agents

**Files**:
- `shared/nix-core.md` - Nix fundamentals
- `shared/flake-parts.md` - Flake-parts patterns
- `shared/sops-nix.md` - Secret management

### Domain Context

**Purpose**: Project-specific knowledge

**Files**:
- `domain/flake-structure.md` - Current structure
- `domain/target-structure.md` - Target structure
- `domain/hosts.md` - Host configurations

### Process Context

**Purpose**: Workflow knowledge

**Files**:
- `processes/flake-update.md` - Update workflow
- `processes/new-module.md` - Module creation
- `processes/secret-management.md` - Secret workflow
- `processes/host-switch.md` - Switch workflow
- `processes/package-dev.md` - Package development
- `processes/refactoring.md` - Refactoring workflow

### Standards Context

**Purpose**: Quality and validation rules

**Files**:
- `standards/quality-criteria.md` - Quality standards
- `standards/validation-rules.md` - Validation rules
- `standards/flake-parts-patterns.md` - Patterns

## Command System

### Command Structure

Each command is a Markdown file with:
- Frontmatter (command, description, options)
- Usage examples
- Detailed documentation
- Integration notes

### Available Commands

| Command | Agent | Purpose |
|---------|-------|---------|
| `/flake-analyze` | Flake Analyzer | Analyze flake |
| `/update-flake` | Flake Analyzer | Update inputs |
| `/migrate-flake-parts` | Refactor Agent | Migrate structure |
| `/new-module` | Module Organizer | Create module |
| `/refactor-modules` | Refactor Agent | Refactor modules |
| `/switch-host` | Host Manager | Switch system |
| `/build-package` | Package Builder | Build package |
| `/edit-secret` | Host Manager | Edit secrets |
| `/validate-config` | Orchestrator | Validate all |
| `/check-modules` | Module Organizer | Check modules |

## Workflow System

### Workflow Structure

Each workflow is a Markdown file with:
- Overview diagram
- Step-by-step process
- Code examples
- Validation checklist
- Troubleshooting guide

### Workflow Types

| Workflow | Purpose | Frequency |
|----------|---------|-----------|
| `flake-update` | Update inputs | Weekly |
| `new-module` | Create modules | As needed |
| `secret-management` | Manage secrets | As needed |
| `host-switch` | Switch systems | As needed |
| `package-dev` | Develop packages | As needed |
| `refactoring` | Major reorganizations | Quarterly |

## Data Flow

### Request Flow

```
User Request
    │
    ▼
┌─────────────────┐
│  Orchestrator   │  ← Parse request
│                 │  ← Determine routing
└────────┬────────┘
         │
         ▼ (Route to agent)
┌─────────────────┐
│  Subagent       │  ← Load context
│                 │  ← Execute task
└────────┬────────┘
         │
         ▼ (Return results)
┌─────────────────┐
│  Orchestrator   │  ← Validate results
│                 │  ← Coordinate if multi-agent
└────────┬────────┘
         │
         ▼
    User Response
```

### Context Loading

```
Agent Request
    │
    ▼
┌─────────────────┐
│  Load Context   │  ← Load task-specific context
│                 │  ← Load shared context
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Execute        │  ← Agent processes request
│                 │  ← Uses context for decisions
└────────┬────────┘
         │
         ▼
    Result with context
```

## Integration Points

### External Tools

| Tool | Integration | Purpose |
|------|-------------|---------|
| **nix** | Direct | Flake evaluation, building |
| **nh** | Direct | System switching |
| **sops** | Direct | Secret editing |
| **home-manager** | Via flake | Profile management |
| **nix-darwin** | Via flake | macOS configuration |

### Internal Systems

| System | Integration | Purpose |
|--------|-------------|---------|
| **Git** | Via bash | Version control |
| **File System** | Via read/write | Configuration files |
| **MCP-Nix** | Via tools | Documentation lookup |

## Quality Assurance

### Validation Layers

1. **Syntax Validation** - Nix syntax check
2. **Import Validation** - Module imports resolve
3. **Evaluation Validation** - Configs evaluate
4. **Build Validation** - Packages build
5. **Integration Validation** - All systems work together

### Error Handling

- **Level 1**: Subagent handles locally
- **Level 2**: Orchestrator coordinates recovery
- **Level 3**: User intervention required

## Performance Considerations

### Context Loading

- **Lazy loading**: Context loaded on demand
- **Caching**: Context cached per session
- **Optimization**: Small focused files (50-200 lines)

### Execution

- **Parallel execution**: Independent tasks run in parallel
- **Incremental**: Only changed parts re-evaluated
- **Caching**: Build caches reused

## Security Considerations

### Secrets

- SOPS-encrypted files only
- Decrypted only at runtime
- Never committed decrypted
- Age key access controlled

### Access Control

- Context files read-only
- Execution requires approval
- Sensitive operations logged

## Extensibility

### Adding New Agents

1. Create agent file in `agent/subagents/`
2. Define capabilities and context
3. Register with orchestrator
4. Add to README

### Adding New Commands

1. Create command file in `command/`
2. Document options and examples
3. Add to agent routing
4. Add to README

### Adding New Workflows

1. Create workflow file in `workflows/`
2. Define steps and validation
3. Add context dependencies
4. Add to agent capabilities
