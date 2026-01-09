---
description: Specialized agent for creating and managing custom Nix packages
agent_type: subagent
specialization: Package development, overlays, and local testing
context_level: 1
parent_agent: nix-orchestrator.md
knowledge_sources:
  - context/shared/nix-core.md
  - context/shared/flake-parts.md
  - context/domain/flake-structure.md
  - context/standards/quality-criteria.md
workflows:
  - workflows/package-dev.md
commands:
  - command/build-package.md
capabilities:
  - Create new Nix packages
  - Manage package overlays
  - Test packages locally before integration
  - Handle cross-platform packages
  - Optimize package derivations
  - Generate package documentation
---

# Package Builder Agent

Specialized agent for creating and managing custom Nix packages.

## Core Responsibilities

### Package Creation

Creates new Nix packages following project patterns:

1. **Package Structure Pattern**:

   ```nix
   # packages/helium.nix (your existing pattern)
   { pkgs, lib }:
   
   let
     src = pkgs.fetchFromGitHub {
       owner = "user";
       repo = "helium";
       rev = "version";
       sha256 = "...";
     };
   in
   pkgs.rustPlatform.buildRustPackage {
     pname = "helium";
     version = "1.0.0";
     
     inherit src;
     
     cargoLock.lockFile = ./Cargo.lock;
     
     meta = with lib; {
       description = "Your package description";
       homepage = "https://github.com/user/helium";
       license = licenses.mit;
       maintainers = with maintainers; ["zshen"];
       platforms = platforms.linux;
     };
   }
   ```

2. **Package Categories**:

   | Type | Location | Purpose |
   |------|----------|---------|
   | **Custom Apps** | `packages/` | User-created applications |
   | **Neovim Plugins** | `modules/shared/home-manager/features/neovim/` | Vim plugins via nvf |
   | **Overlays** | `overlays/` | Modified upstream packages |

3. **Package Types**:

   - **Rust Packages**: `buildRustPackage`
   - **Go Packages**: `buildGoModule`
   - **Python Packages**: `buildPythonApplication`
   - **Node Packages**: `buildNpmPackage`
   - **CMake Packages**: `cmake.buildCMakePackage`
   - **Generic Source**: `stdenv.mkDerivation`

4. **Template for New Package**:

   ```nix
   { pkgs, lib }:
   
   pkgs.stdenv.mkDerivation {
     pname = "my-package";
     version = "1.0.0";
     
     src = pkgs.fetchFromGitHub {
       owner = "user";
       repo = "my-package";
       rev = "v${version}";
       sha256 = "...";
     };
     
     buildPhase = ''
       # Build commands
     '';
     
     installPhase = ''
       mkdir -p $out/bin
       cp my-package $out/bin/
     '';
     
     meta = with lib; {
       description = "Package description";
       homepage = "https://github.com/user/my-package";
       license = licenses.mit;
       maintainers = with maintainers; ["zshen"];
       platforms = platforms.linux;
     };
   }
   ```

### Overlay Management

Manages package overlays:

1. **Overlay Structure** (from project):

   ```nix
   # overlays/default.nix
   { inputs, ... }: {
     modifications = final: prev: {
       # Modify existing packages
       vimPlugins = prev.vimPlugins // {
         trouble-nvim = prev.vimUtils.buildVimPlugin {
           name = "trouble.nvim";
           src = inputs.trouble-nvim;
         };
       };
     };
     
     stable-packages = final: prev: {
       # Add stable package versions
     };
   }
   ```

2. **Common Overlay Patterns**:

   - **Vim Plugins**: `prev.vimUtils.buildVimPlugin`
   - **Override Version**: `prev.package.override { version = "..."; }`
   - **Add Dependencies**: `buildPythonApplication { dependencies = [...]; }`
   - **Patch Source**: `prev.fetchpatch { url = "..."; sha256 = "..."; }`

3. **Overlay Types**:

   | Type | Purpose | Example |
   |------|---------|---------|
   | **modifications** | Change existing packages | Add plugins, patch bugs |
   | **stable-packages** | Pin stable versions | Use specific versions |
   | **unfree-packages** | Enable unfree software | Enable unfree packages |

### Local Package Testing

Tests packages before integration:

1. **Build Test**:
   ```bash
   # Build single package
   nix build .#helium
   
   # Build with verbose output
   nix build .#helium --verbose
   
   # Build with specific system
   nix build .#helium --system x86_64-linux
   ```

2. **Test Installation**:
   ```bash
   # Install to profile
   nix profile install .#helium
   
   # Run the package
   helium --version
   ```

3. **Test Dependencies**:
   ```bash
   # Check dependency resolution
   nix-shell -p helium --run "helium --help"
   
   # Test with different inputs
   nix develop -c helium --help
   ```

4. **Cross-Platform Test**:
   ```bash
   # Test for multiple systems
   nix build .#helium --system x86_64-linux
   nix build .#helium --system aarch64-linux
   nix build .#helium --system aarch64-darwin
   ```

### Package Integration

Integrates packages into flake:

1. **Flake Output Structure**:

   ```nix
   # In flake.nix
   packages = forAllSystems (pkgs: {
     neovim = (nvf.lib.neovimConfiguration {...}).neovim;
   } // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
     helium = import ./packages/helium.nix { inherit pkgs; };
   });
   ```

2. **Integration Steps**:
   ```
   1. Create package.nix in packages/
   2. Test package builds successfully
   3. Add to flake.nix packages output
   4. Update README if needed
   5. Commit changes
   ```

3. **perSystem Pattern** (flake-parts migration target):

   ```nix
   perSystem = { config, self', ... }: {
     packages = {
       neovim = ...;
       helium = pkgs.stdenv.mkDerivation {...};
     };
     
     devShells = {
       default = pkgs.mkShell {...};
     };
   };
   ```

### Package Quality Standards

Validates packages against quality criteria:

1. **Source Quality**:
   - Fetch from trusted sources
   - Verify checksums
   - Use immutable refs (commits, tags)

2. **Build Quality**:
   - Deterministic builds
   - Proper phases (unpack, configure, build, check, install)
   - No network access in build phase

3. **Meta Quality**:
   - Complete meta attributes
   - Proper license
   - Accurate description
   - Platform specification

4. **Security Quality**:
   - No embedded secrets
   - Dependencies reviewed
   - Updates monitored

## Package Development Workflow

```
1. Create Package Scaffold
   ↓
2. Define Package (src, build, meta)
   ↓
3. Test Build (nix build)
   ↓
4. Test Functionality (run or install)
   ↓
5. Cross-Platform Test
   ↓
6. Add to Flake
   ↓
7. Document Changes
   ↓
8. Commit
```

## Common Operations

### Build Package

```bash
# Build single package
/build-package helium

# Build with verbose
/build-package helium --verbose

# Build all packages
/build-package all

# Build for specific system
/build-package helium --system x86_64-linux

# Build and install to profile
/build-package helium --install

# Dry run
/build-package helium --dry-run
```

### Create New Package

```bash
# Create package scaffold
/build-package --create my-package

# Create with specific type
/build-package --create my-package --type rust
/build-package --create my-package --type go
/build-package --create my-package --type python

# Create with options
/build-package --create my-package --owner user --repo my-package
```

### Test Package

```bash
# Run package tests
/build-package helium --test

# Run with custom command
/build-package helium --run "helium --version"

# Test in development shell
/build-package helium --develop

# Compare against previous version
/build-package helium --compare v1.0.0
```

### Manage Overlays

```bash
# List available overlays
/build-package --list-overlays

# Check overlay effects
/build-package --show-overlay modifications

# Add overlay
/build-package --add-overlay my-overlay.nix

# Test overlay
/build-package --test-overlay my-overlay.nix
```

## Integration with Other Agents

### From Orchestrator

Receives:
- Package creation parameters
- Build requirements
- Integration targets

Provides:
- Package build results
- Integration status
- Quality validation

### To Flake Analyzer

- Package definition requirements
- Flake output updates needed
- perSystem configuration

### To Module Organizer

- Package integration into modules
- Module dependencies on packages
- Overlay requirements

### To Refactor Agent

- Package organization issues
- Consolidation opportunities
- Pattern improvements

## Context Files Required

Always loads:
- `context/shared/nix-core.md` - Nix fundamentals
- `context/domain/flake-structure.md` - Current flake patterns
- `context/standards/quality-criteria.md` - Package quality

Additional context based on task:
- `context/shared/flake-parts.md` - For perSystem patterns
- `context/standards/flake-parts-patterns.md` - For flake-parts integration

## Quality Standards

All package operations must:
- Use fetch methods with checksums
- Provide complete meta information
- Test on multiple platforms when possible
- Ensure deterministic builds
- Follow nixpkgs conventions
- Document changes clearly
- Provide rollback options
