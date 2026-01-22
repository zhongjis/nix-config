# Draft: Migrate nix-config-private to flake-parts

## Context Gathered

### Current State Analysis

**Main repo (nix-config):**
- ✅ Using flake-parts with modular structure
- Has `flake-parts/` directory with:
  - `modules.nix` - Auto-discovers modules using import-tree
  - `systems.nix` - System configurations
  - `overlays.nix` - Overlay exports  
  - `packages.nix` - Per-system packages
  - `templates.nix` - Flake templates

**Private repo (nix-config-private):**
- ❌ Traditional flake structure (no flake-parts)
- Simple structure:
  - `modules/adobe-marketo-flex/` with 6 submodules
  - `secrets/` with 2 encrypted yaml files
  - Exposes: `homeModules.zshen-nix-config-private`

**Integration:**
- Main repo imports private via: `inputs.nix-config-private.homeModules.zshen-nix-config-private`
- Used in `hosts/mac-m1-max/home.nix`
- Enables with: `zshen-private-flake.adobe-marketo-flex.enable = true`

### Module Dependencies

**adobe-marketo-flex module structure:**
```
default.nix          - Main enable option and imports
├── git.nix          - Git user config (simple)
├── ssh.nix          - SSH keys + 20+ host configs (heavy sops usage)
├── sbt.nix          - SBT credentials (2 sops secrets)
├── mvn.nix          - Maven settings.xml (2 sops secrets, uses builtins.readFile)
└── zsh/
    ├── default.nix  - Env vars from secrets (4 sops secrets)
    └── balabit.sh   - Helper function
```

**Secrets dependencies:**
- All modules reference `../../secrets/adobe.yaml` (or `../../../` from zsh)
- Total unique secrets used: ~10 from adobe.yaml
- Methods of use:
  - `cat ${config.sops.secrets.name.path}` (in shell/env vars)
  - `builtins.readFile config.sops.secrets.name.path` (in XML templates)

### Critical Issue: Bootstrap Problem

**The Problem:**
When setting up a new machine:
1. Initial `home-manager switch` runs
2. sops-nix tries to decrypt secrets using `~/.config/sops/age/keys.txt`
3. **Key doesn't exist yet** (not provisioned by HM module)
4. Build fails, preventing HM from creating the SSH keys that would provision the age key

**User's Requirement:**
> "make sure the private flake will be ignored if sops age key not found. as at current set up, private flake will fail the build on initial setup when ssh key not provisioned by hm module."

## Research Findings

### From explore agents:
- Current repo uses `lib.mkDefault true` for optional module loading
- No existing graceful degradation patterns for missing secrets
- Uses `builtins.pathExists` in one darwin module

### From librarian - flake-parts patterns:
✅ **Key insights:**
1. Use `flake.nixosModules`, `flake.darwinModules`, `flake.homeModules` in flake-parts
2. Auto-discovery with import-tree or custom readModules function
3. Multiple export patterns: default + named bundles
4. `lib.mkIf` for conditional activation
5. Early module injection for passing custom args

### From librarian - sops graceful degradation:
[PENDING - will incorporate when complete]

## Design Decisions (Based on User Preferences)

1. **Naming:** Keep existing `zshen-private-flake.*` namespace ✅
2. **Module organization:** Option B - Work-profile bundles ✅
3. **Future support:** Plan for NixOS/Darwin/packages/overlays ✅
4. **Breaking changes:** Acceptable as long as they work ✅
5. **Sops handling:** Must gracefully degrade when key missing ✅

