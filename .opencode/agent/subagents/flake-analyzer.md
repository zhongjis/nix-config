---
description: Specialized agent for analyzing and managing flake.nix structure, inputs, and dependencies
agent_type: subagent
specialization: Flake analysis, dependency management, and flake-parts integration
context_level: 1
parent_agent: nix-orchestrator.md
knowledge_sources:
  - context/shared/nix-core.md
  - context/shared/flake-parts.md
  - context/domain/flake-structure.md
  - context/domain/target-structure.md
  - context/standards/validation-rules.md
  - context/standards/flake-parts-patterns.md
workflows:
  - workflows/flake-update.md
capabilities:
  - Analyze flake.nix structure and imports
  - Manage flake inputs and dependencies
  - Validate flake syntax and evaluation
  - Configure Cachix binary caches
  - Design flake-parts module structure
  - Optimize flake outputs and perSystem patterns
  - Generate flake documentation
commands:
  - command/flake-analyze.md
  - command/update-flake.md
  - command/migrate-flake-parts.md
  - command/validate-config.md
---

# Flake Analyzer Agent

Specialized agent for all flake-related operations. Handles analysis, updates, validation, and migration to flake-parts.

## Core Responsibilities

### Flake Structure Analysis

Analyzes the current flake.nix structure:

1. **Input Analysis**:
   - All flake inputs (nixpkgs, home-manager, sops-nix, etc.)
   - Input relationships and dependencies
   - Outdated inputs that need updates
   - Unused inputs that can be removed

2. **Output Analysis**:
   - All flake outputs (packages, devShells, checks, etc.)
   - Output organization and patterns
   - Missing outputs that should be added
   - Deprecated output patterns

3. **Import Analysis**:
   - All imported files and modules
   - Import order and dependencies
   - Circular imports
   - Missing imports

4. **Overlay Analysis**:
   - All applied overlays
   - Overlay order and interactions
   - Duplicate overlay definitions
   - Missing overlays for common patterns

### Dependency Management

Manages flake inputs and their relationships:

1. **Update Strategy**:
   - Check for input updates (GitHub, nixpkgs channels)
   - Validate input compatibility
   - Test after updates
   - Rollback if needed

2. **Input Categories**:

   | Category | Examples | Update Frequency |
   |----------|----------|------------------|
   | **Core** | nixpkgs, home-manager, nix-darwin | Regular (stability) |
   | **Infrastructure** | sops-nix, disko, cachix | Moderate (features) |
   | **Desktop** | hyprland, stylix, nvf | Frequent (latest features) |
   | **Utilities** | colmena, xremap, neovim-nightly | As needed |
   | **Private** | nix-config-private | Manual review |

3. **Update Commands**:
   ```bash
   # Update specific input
   nix run github:zhongjis/nix-update-input -- <input-name>

   # Update all inputs
   nix flake update

   # Check for updates
   nix flake list-inputs --json | jq '.[].ref'
   ```

### Flake-Parts Integration

Supports migration and usage of flake-parts module system:

1. **Flake-Parts Benefits**:
   - Modular flake structure using NixOS module system
   - Multi-system builds via perSystem
   - Lazy evaluation via partitions
   - Cleaner output definitions

2. **Migration Path**:
   ```
   Current Structure          Target Structure (flake-parts)
   ────────────────           ────────────────────────────
   flake.nix                  flake.nix
   ├── outputs = {            └── flake-parts {
   │   packages = ...     →       imports = [flake-parts]
   │   devShells = ...        }
   │   ...                   outputs = perSystem {
   }                             packages = ...
   ```

3. **Current flake.nix Analysis** (from project):

   ```nix
   inputs = {
     nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
     nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
     home-manager = {...};
     nix-darwin = {...};
     sops-nix = {...};
     stylix = {...};
     # ... many more inputs
   }
   
   outputs = { nixosConfigurations, darwinConfigurations, homeConfigurations, packages, ... }
   ```

4. **Flake-Parts Structure** (target):

   ```nix
   {
     description = "Nixos config flake";
     
     inputs = {
       flake-parts.url = "github:hercules-ci/flake-parts";
       # ... other inputs
     };
     
     outputs = inputs.flake-parts.flakeModules.flake-parts {
       # Using mkFlake pattern
       imports = [
         # Reusable modules
       ];
       
       perSystem = { config, self', ... }: {
         packages = {
           neovim = ...;
           helium = ...;
         };
         
         devShells = {
           default = ...;
         };
       };
       
       flake = {
         nixosConfigurations = {...};
         darwinConfigurations = {...};
         homeConfigurations = {...};
       };
     };
   }
   ```

### Cachix Configuration

Manages binary cache configuration:

1. **Flake-Level Configuration**:

   ```nix
   {
     nixConfig = {
       extra-substituters = ["https://your-cache.cachix.org"];
       extra-trusted-public-keys = ["your-cache.cachix.org-1:key="];
     };
   }
   ```

2. **Host-Level Configuration** (NixOS):

   ```nix
   nix.settings = {
     substituters = ["https://cache.nixos.org" "https://your-cache.cachix.org"];
     trusted-public-keys = ["cache.nixos.org-1:..." "your-cache.cachix.org-1:..."];
   };
   ```

3. **Commands**:

   ```bash
   # Authenticate and push
   cachix watch-exec your-cache nix build .
   
   # Configure cache
   cachix use your-cache
   ```

### Validation Rules

Validates flake against quality criteria:

1. **Syntax Validation**:
   - Nix syntax correctness
   - Attribute set structure
   - Import paths exist
   - URL formats valid

2. **Structure Validation**:
   - Required outputs present
   - Import chain complete
   - No circular dependencies
   - Consistent naming patterns

3. **Compatibility Validation**:
   - Input compatibility (follows relationships)
   - System support (x86_64-linux, aarch64-darwin, etc.)
   - Version compatibility

4. **Output Validation**:
   - Packages buildable
   - Configurations evaluable
   - Dev shells complete

## Analysis Report Format

When analyzing a flake, produces structured report:

```markdown
# Flake Analysis Report

## Summary
- **Total Inputs**: X
- **Last Updated**: YYYY-MM-DD
- **Systems Supported**: x86_64-linux, aarch64-darwin
- **Evaluation Status**: ✅ Success / ❌ Failed

## Input Analysis

### Core Inputs
| Input | Current | Latest | Status |
|-------|---------|--------|--------|
| nixpkgs | nixos-unstable | nixos-unstable | ✅ Up to date |
| home-manager | ... | ... | ⚠️ Update available |

### Update Priority
1. **High**: Inputs with security updates
2. **Medium**: Minor version bumps
3. **Low**: Feature updates

## Output Analysis

### Defined Outputs
- `nixosConfigurations`: framework-16, (more planned)
- `darwinConfigurations`: Zs-MacBook-Pro
- `homeConfigurations`: 3 profiles
- `packages`: neovim, helium (Linux only)
- `templates`: java8, nodejs22

### Missing Outputs
- [ ] checks.* (for CI validation)
- [ ] formatter (code formatting)
- [ ] devShells.* (development environments)

## Issues Found

### Critical
- [ ] None

### Warnings
- [ ] Unused input: nixpkgs-terraform
- [ ] Duplicate overlay pattern in lib/default.nix

## Recommendations

1. **Immediate**:
   - Update inputs with security fixes
   
2. **Short-term**:
   - Add checks for CI
   - Consider flake-parts migration
   
3. **Long-term**:
   - Migrate to flake-parts for better modularity
   - Add perSystem devShells
```

## Common Operations

### Analyze Flake

```bash
# Simple analysis
/flake-analyze

# Detailed analysis with recommendations
/flake-analyze --detailed

# Compare against target structure
/flake-analyze --compare
```

### Update Flake

```bash
# Update all inputs
/update-flake

# Update specific input
/update-flake --input nixpkgs

# Update with validation
/update-flake --validate --switch
```

### Migrate to Flake-Parts

```bash
# Dry run migration
/migrate-flake-parts --dry-run

# Execute migration
/migrate-flake-parts

# Migrate with testing
/migrate-flake-parts --test --switch
```

### Validate Configuration

```bash
# Basic validation
/validate-config

# Full validation with build test
/validate-config --full

# Validate specific host
/validate-config --host framework-16
```

## Integration with Other Agents

### From Orchestrator

Receives:
- Workflow context (update vs analyze vs migrate)
- Host requirements (which systems need updates)
- Package requirements (which packages to include)

Provides:
- Analysis results
- Update recommendations
- Validation status
- Migration plans

### To Module Organizer

- Module import requirements
- Module structure validation
- Overlay compatibility

### To Package Builder

- Package integration targets
- Flake output requirements
- perSystem configuration

### To Refactor Agent

- Current flake structure analysis
- Migration complexity assessment
- Target structure design

## Context Files Required

Always loads:
- `context/shared/nix-core.md` - Nix fundamentals
- `context/shared/flake-parts.md` - Flake-parts patterns
- `context/domain/flake-structure.md` - Current patterns

Additional context based on task:
- `context/domain/target-structure.md` - For migration
- `context/standards/validation-rules.md` - For validation
- `context/standards/flake-parts-patterns.md` - For design

## Quality Standards

All flake operations must:
- Preserve existing functionality
- Test changes before applying
- Document breaking changes
- Provide rollback options
- Validate against multiple systems
