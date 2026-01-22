# Flake-Parts Migration Proposal

## Executive Summary

This proposal outlines a phased migration strategy to adopt `flake-parts` and replace custom `lib/` utilities with flake-parts built-in methods. The migration preserves your existing modular architecture while gaining the benefits of the NixOS module system for flake organization.

**Key Goals:**
1. Replace `forAllSystems` with `perSystem` (straightforward win)
2. Adopt flake-parts module system for better organization
3. Reduce custom glue code where flake-parts provides equivalent functionality
4. Preserve your battle-tested `extendModules` pattern (it's valuable!)
5. Enable feature-based organization for future scalability

---

## Current State Analysis

### What You Have

**Custom lib/default.nix provides:**
- `mkSystem` - System builder with overlays, modules, specialArgs
- `mkHome` - Home Manager configuration builder
- `forAllSystems` - Multi-system package generation
- `extendModules` - Automatic enable options for features/bundles/services
- `filesIn` / `dirsIn` / `fileNameOf` - Directory traversal helpers
- Special args: `currentSystem`, `currentSystemName`, `currentSystemUser`, `isDarwin`

**Module Organization:**
```
modules/
├── nixos/
│   ├── bundles/     (7 files: 3d-printing, developer, gaming, etc.)
│   ├── features/    (15+ files: docker, flatpak, hyprland, etc.)
│   └── services/    (Various system services)
├── darwin/
│   ├── bundles/     (general, work)
│   └── features/    (yabai, skhd, sketchybar, etc.)
└── shared/          (shared between nixos/darwin)
```

**Strengths:**
- ✅ Clean modular organization with automatic enable options
- ✅ DRY principle - no repeated configuration
- ✅ Type safety through NixOS module system
- ✅ Reusable across NixOS and Darwin

**Pain Points:**
- ⚠️ Custom `forAllSystems` is manual and verbose
- ⚠️ Special args require manual plumbing
- ⚠️ No lazy evaluation (all inputs fetched always)
- ⚠️ Hard to publish reusable modules
- ⚠️ Overlays applied manually in mkSystem/mkHome

---

## What Flake-Parts Provides

### Built-in Functionality

| Feature | Current Implementation | flake-parts Equivalent |
|---------|----------------------|----------------------|
| Multi-system packages | `forAllSystems` | `perSystem` |
| System context | `currentSystem` special arg | `system` in perSystem |
| Package access | Manual `pkgs` passing | `pkgs`, `self'`, `inputs'` |
| Module composition | `imports` in mkSystem | `imports` in mkFlake |
| Overlays | Manual in mkSystem | Automatic in perSystem |
| Publishing modules | Custom | `flake.modules` |
| Lazy evaluation | None | `partitions` |

### Key Benefits

1. **Automatic System Handling**: No more `genAttrs` over system list
2. **Better Module Arguments**: `self'`, `inputs'` for clean cross-referencing
3. **Lazy Evaluation**: Use partitions to avoid fetching unused inputs
4. **Module Publishing**: `flake.modules` for reusable components
5. **Community Ecosystem**: treefmt-nix, pre-commit-hooks, rust-flake, etc.
6. **Error Messages**: Module system validation and helpful errors

---

## Migration Strategy

### Phase 1: Foundation (Low Risk, High Value)

**Objective**: Adopt flake-parts structure without breaking existing functionality

**Changes:**
1. ✅ You already have `flake-parts` in inputs!
2. Wrap `outputs` with `flake-parts.lib.mkFlake`
3. Define `systems` list
4. Move `packages` to `perSystem`
5. Keep `mkSystem` and `mkHome` in `flake` attribute for now

**Example:**

```nix
# flake.nix
{
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./flake-parts/packages.nix
        ./flake-parts/devshells.nix
        ./flake-parts/systems.nix
      ];
    };
}
```

```nix
# flake-parts/packages.nix
{ inputs, ... }:
{
  perSystem = { config, pkgs, system, ... }: {
    packages = {
      # Replace forAllSystems!
      neovim = (inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [ ../modules/home-manager/neovim/nvf ];
      }).neovim;
      
      helium = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
        import ../packages/helium.nix {
          inherit pkgs;
          lib = pkgs.lib;
        }
      );
    };
  };
}
```

```nix
# flake-parts/systems.nix
{ inputs, lib, ... }:
let
  overlays = import ../overlays { inherit inputs; };
  myLib = import ../lib/default.nix { inherit overlays nixpkgs inputs; };
in
{
  flake = with myLib; {
    nixosConfigurations = {
      framework-16 = mkSystem "framework-16" {
        system = "x86_64-linux";
        hardware = "framework-16-7040-amd";
        user = "zshen";
      };
    };

    darwinConfigurations = {
      Zs-MacBook-Pro = mkSystem "mac-m1-max" {
        system = "aarch64-darwin";
        user = "zshen";
        darwin = true;
      };
    };

    homeConfigurations = {
      "zshen@Zs-MacBook-Pro" = mkHome "mac-m1-max" {
        system = "aarch64-darwin";
        darwin = true;
      };
      # ... others
    };
  };
}
```

**Impact:**
- ✅ Simple, low-risk change
- ✅ Immediately gain perSystem benefits
- ✅ No changes to modules or hosts
- ✅ Can iterate from here

**Timeline**: 1-2 hours

---

### Phase 2: Overlays & Module Publishing (Medium Value)

**Objective**: Use flake-parts for overlays and expose reusable modules

**Changes:**

1. **Move overlays to flake-parts:**

```nix
# flake-parts/overlays.nix
{ inputs, ... }:
{
  flake.overlays = {
    modifications = final: prev: {
      # Your modifications
    };
    
    stable-packages = final: _prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.system;
        config.allowUnfree = true;
      };
    };
    
    default = final: prev:
      (inputs.self.overlays.modifications final prev)
      // (inputs.self.overlays.stable-packages final prev);
  };
}
```

2. **Publish your reusable modules:**

```nix
# flake-parts/modules.nix
{ ... }:
{
  flake = {
    nixosModules.default = ../modules/nixos;
    darwinModules.default = ../modules/darwin;
    homeManagerModules.default = ../modules/home-manager;
    
    # Expose individual features
    nixosModules = {
      hyprland = ../modules/nixos/features/hyprland.nix;
      docker = ../modules/nixos/features/docker.nix;
      kubernetes = ../modules/nixos/features/kubernetes.nix;
      # ... etc
    };
    
    darwinModules = {
      yabai = ../modules/darwin/features/yabai;
      skhd = ../modules/darwin/features/skhd;
      # ... etc
    };
  };
}
```

**Benefits:**
- Others can use your modules: `inputs.your-config.nixosModules.hyprland`
- Better documentation of public API
- Can use in templates

**Impact:**
- ✅ Enables code reuse across repos
- ✅ Documents your module structure

**Timeline**: 2-3 hours

---

### Phase 3: Simplify mkSystem/mkHome (Optional, High Complexity)

**Objective**: Reduce custom code in mkSystem/mkHome by using flake-parts patterns

**Current mkSystem does:**
1. Chooses between nixosSystem and darwinSystem
2. Applies overlays
3. Adds hardware configuration
4. Adds sops/determinate modules
5. Injects special args (currentSystem, currentSystemName, etc.)

**flake-parts approach:**

```nix
# flake-parts/systems.nix - Alternative approach
{ inputs, withSystem, ... }:
{
  flake.nixosConfigurations = {
    framework-16 = withSystem "x86_64-linux" ({ config, pkgs, ... }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          currentSystem = "x86_64-linux";
          currentSystemName = "framework-16";
          currentSystemUser = "zshen";
          isDarwin = false;
          outputs = inputs.self;
          myLib = import ../lib/default.nix { 
            inherit overlays nixpkgs inputs;
          };
        };
        modules = [
          ../hosts/framework-16/configuration.nix
          inputs.nixos-hardware.nixosModules.framework-16-7040-amd
          inputs.determinate.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          
          # Apply overlays
          {
            nixpkgs.overlays = [
              inputs.self.overlays.default
            ];
            nixpkgs.config.allowUnfree = true;
          }
        ];
      });
  };
}
```

**Analysis:**
- ⚠️ More verbose than mkSystem
- ⚠️ Repeats overlay/module configuration per host
- ✅ More explicit (easier for others to understand)
- ✅ Standard flake-parts pattern

**Recommendation:**
- **KEEP mkSystem/mkHome for now** - they're good abstractions!
- Only migrate if you want maximum flake-parts purity
- Could create a flake-parts module that provides mkSystem-like helpers

**Timeline**: 4-6 hours (if pursued)

---

### Phase 4: Feature-Based Organization (Future, Optional)

**Objective**: Dendritic pattern - every file is a flake-parts module

Inspired by [drupol/infra](https://github.com/drupol/infra) migration.

**Current structure:**
```
modules/nixos/bundles/general-desktop.nix  # Enable via myNixOS.bundles.general-desktop.enable
hosts/framework-16/configuration.nix       # myNixOS.bundles.general-desktop.enable = true;
```

**Feature-based structure:**
```
modules/features/desktop/default.nix       # Declares flake.modules.nixos.desktop
modules/features/desktop/apps.nix          # Declares flake.modules.nixos.desktop-apps
modules/features/dev/default.nix           # Declares flake.modules.nixos.dev
hosts/framework-16/default.nix             # imports desktop + desktop-apps + dev modules
```

**Example:**

```nix
# modules/features/desktop/default.nix
{ config, lib, pkgs, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    services.xserver.enable = true;
    services.pipewire.enable = true;
    # Desktop base config
  };
  
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    # Desktop home-manager config
  };
}
```

```nix
# hosts/framework-16/default.nix
{ config, ... }:
{
  flake.nixosConfigurations.framework-16 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      config.flake.modules.nixos.desktop
      config.flake.modules.nixos.desktop-apps
      config.flake.modules.nixos.dev
      config.flake.modules.nixos.gaming
      ./hardware-configuration.nix
    ];
  };
}
```

**Analysis:**
- ⚠️ Large refactor, breaks all existing configs
- ⚠️ Loses automatic enable options from extendModules
- ✅ More explicit about feature dependencies
- ✅ Better for multi-repo reuse
- ✅ Easier to understand for newcomers

**Recommendation:**
- **Do NOT pursue initially** - too disruptive
- Your current extendModules pattern is excellent
- Only consider if you need to publish modules extensively

**Timeline**: 10-20 hours + testing

---

## What to Keep from Your Custom lib/

### ✅ KEEP These (They're Great!)

1. **extendModules pattern**
   - Automatically creates enable options
   - Wraps configs with mkIf conditions
   - This is genuinely valuable, not replaceable by flake-parts
   
2. **filesIn / dirsIn / fileNameOf**
   - Simple utilities for directory traversal
   - flake-parts doesn't provide these
   - Consider using `import-tree` library if you want automatic imports

3. **mkSystem / mkHome** (at least initially)
   - Good abstractions that encapsulate complexity
   - Makes host configs much cleaner
   - Can coexist with flake-parts

### ❌ REPLACE These

1. **forAllSystems**
   - Directly replaced by `perSystem`
   - No reason to keep custom version

2. **pkgsFor**
   - Unused currently
   - perSystem provides `pkgs` automatically

### 🤔 EVALUATE These

1. **Special args (currentSystem, currentSystemName, etc.)**
   - `currentSystem` → perSystem provides `system`
   - `currentSystemName` → Could use `config.networking.hostName` or pass explicitly
   - `currentSystemUser` → Pass explicitly or use NixOS options
   - `isDarwin` → Could use `pkgs.stdenv.isDarwin` or pass explicitly

   **Recommendation**: Keep for now, they make configs cleaner

---

## Risk Assessment

### Low Risk Changes
- ✅ Phase 1 (Foundation) - Non-breaking, additive
- ✅ Phase 2 (Module Publishing) - Pure additions

### Medium Risk Changes
- ⚠️ Phase 3 (Simplify mkSystem) - Changes core abstractions
- ⚠️ Replacing special args - Requires module updates

### High Risk Changes
- ❌ Phase 4 (Feature-based refactor) - Complete reorg

---

## Recommended Path Forward

### Minimal Migration (Recommended)

**Do this first:**
1. ✅ Phase 1: Adopt flake-parts structure
2. ✅ Phase 2: Publish modules
3. ✅ Replace `forAllSystems` with `perSystem`
4. ✅ Keep everything else as-is

**Result:**
- Best of both worlds
- Gain flake-parts benefits without losing custom abstractions
- Can iterate further if desired

**Time investment**: 4-6 hours
**Risk**: Very Low
**Reward**: High (immediate perSystem benefits)

### Progressive Migration (If time permits)

1. Phase 1 + 2 (as above)
2. Gradually migrate special args to standard patterns
3. Consider feature-based org for new modules only

**Time investment**: 10-15 hours
**Risk**: Medium
**Reward**: Medium (cleaner but more standard)

### Full Migration (Not Recommended)

- Complete feature-based reorg
- Replace all custom lib functions
- Pure flake-parts approach

**Time investment**: 20-30 hours
**Risk**: High
**Reward**: Low (current patterns are already good)

---

## Example: Minimal Migration Result

Here's what your flake would look like after Phase 1 + 2:

```nix
# flake.nix
{
  description = "Nixos config flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # ... all your other inputs
  };
  
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      
      imports = [
        ./flake-parts/packages.nix
        ./flake-parts/systems.nix
        ./flake-parts/overlays.nix
        ./flake-parts/modules.nix
        ./flake-parts/templates.nix
      ];
    };
}
```

```nix
# flake-parts/packages.nix
{ inputs, ... }:
{
  perSystem = { config, pkgs, lib, system, ... }: {
    packages = 
      let
        inherit (lib) optionalAttrs;
      in {
        neovim = (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ ../modules/home-manager/neovim/nvf ];
        }).neovim;
      } // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        helium = import ../packages/helium.nix {
          inherit pkgs;
          lib = pkgs.lib;
        };
      };
  };
}
```

```nix
# flake-parts/systems.nix
{ inputs, lib, ... }:
let
  overlays = import ../overlays { inherit inputs; };
  myLib = import ../lib/default.nix { 
    inherit overlays;
    nixpkgs = inputs.nixpkgs;
    inherit inputs;
  };
in
{
  flake = with myLib; {
    nixosConfigurations = {
      framework-16 = mkSystem "framework-16" {
        system = "x86_64-linux";
        hardware = "framework-16-7040-amd";
        user = "zshen";
      };
    };
    
    darwinConfigurations = {
      Zs-MacBook-Pro = mkSystem "mac-m1-max" {
        system = "aarch64-darwin";
        user = "zshen";
        darwin = true;
      };
    };
    
    homeConfigurations = {
      "zshen@Zs-MacBook-Pro" = mkHome "mac-m1-max" {
        system = "aarch64-darwin";
        darwin = true;
      };
      "zshen@thinkpad-t480" = mkHome "thinkpad-t480" {
        system = "x86_64-linux";
      };
      "zshen@framework-16" = mkHome "framework-16" {
        system = "x86_64-linux";
      };
    };
  };
}
```

```nix
# flake-parts/overlays.nix
{ inputs, ... }:
{
  flake.overlays = import ../overlays { inherit inputs; };
}
```

```nix
# flake-parts/modules.nix
{ ... }:
{
  flake = {
    nixosModules.default = ../modules/nixos;
    nixDarwinModules.default = ../modules/darwin;
    homeManagerModules.default = ../modules/home-manager;
  };
}
```

```nix
# flake-parts/templates.nix
{ ... }:
{
  flake.templates = {
    java8 = {
      path = ../templates/java8;
      description = "nix flake new -t github:zhongjis/nix-config#java8 .";
    };
    nodejs22 = {
      path = ../templates/nodejs22;
      description = "nix flake new -t github:zhongjis/nix-config#nodejs22 .";
    };
  };
}
```

**Key points:**
- ✅ Clean separation of concerns (one file per output type)
- ✅ perSystem for packages (automatic multi-system)
- ✅ Keep mkSystem/mkHome abstractions
- ✅ Keep extendModules pattern
- ✅ Minimal changes to existing code

---

## Testing Strategy

### Phase 1 Testing

```bash
# Check flake structure
nix flake check

# Build packages for all systems
nix build .#neovim
nix build .#helium  # Linux only

# Test system builds (don't switch yet)
nix build .#nixosConfigurations.framework-16.config.system.build.toplevel
nix build .#darwinConfigurations.Zs-MacBook-Pro.system

# Test home-manager builds
nix build .#homeConfigurations."zshen@Zs-MacBook-Pro".activationPackage

# Only switch after successful builds
nh darwin switch .  # macOS
nh os switch .      # NixOS
```

### Rollback Plan

If anything breaks:

```bash
# NixOS
sudo nixos-rebuild switch --rollback

# Darwin
darwin-rebuild switch --rollback

# Or use generation numbers
darwin-rebuild --list-generations
darwin-rebuild switch --switch-generation 41
```

---

## Community Resources

**Official Documentation:**
- [flake.parts](https://flake.parts/) - Official docs
- [flake.parts/options](https://flake.parts/options/flake-parts.html) - All options
- [Multi-platform guide](https://flake.parts/multi-platform)

**Real-World Examples:**
- [drupol/infra](https://github.com/drupol/infra) - Feature-based migration
- [Mic92/dotfiles](https://github.com/Mic92/dotfiles) - Production NixOS+Darwin
- [lazygit](https://github.com/jesseduffield/lazygit/blob/master/flake.nix) - Simple project
- [llama.cpp](https://github.com/ggml-org/llama.cpp/blob/master/flake.nix) - Multi-platform C++

**Community Modules:**
- [treefmt-nix](https://github.com/numtide/treefmt-nix) - Declarative formatting
- [pre-commit-hooks](https://github.com/cachix/pre-commit-hooks.nix) - Git hooks
- [devenv](https://github.com/cachix/devenv) - Dev environments
- [awesome-flake-parts](https://github.com/wearetechnative/awesome-flake-parts) - Curated list

---

## Decision: What Should You Do?

### My Recommendation: **Minimal Migration (Phase 1 + 2)**

**Rationale:**
1. Your custom `extendModules` pattern is **better than pure flake-parts** for your use case
2. `mkSystem`/`mkHome` abstractions are valuable and clean
3. Replacing `forAllSystems` with `perSystem` is an easy win
4. Publishing modules enables future reuse
5. Low risk, high reward

**What NOT to do:**
- ❌ Don't throw away extendModules - it's genuinely good
- ❌ Don't pursue feature-based reorg - too disruptive
- ❌ Don't replace special args unless they cause issues

**Long-term:**
- Use flake-parts for packages, devShells, checks (perSystem stuff)
- Keep custom lib for module organization (extendModules pattern)
- Gradually adopt community modules (treefmt, pre-commit)
- Consider import-tree if you want automatic module discovery

---

## Questions for You

Before proceeding, please clarify:

1. **Primary goal?**
   - Reduce custom code?
   - Better organization?
   - Publish reusable modules?
   - Learn flake-parts patterns?

2. **Risk tolerance?**
   - Minimal changes (Phase 1+2)?
   - Progressive migration (Phase 1+2+3)?
   - Full rewrite (all phases)?

3. **Time investment?**
   - Quick win (4-6 hours)?
   - Moderate effort (10-15 hours)?
   - Major project (20-30 hours)?

4. **Breaking changes acceptable?**
   - No (keep everything working)?
   - Yes, if incremental?
   - Yes, complete rewrite OK?

5. **Module publishing needed?**
   - Yes, want others to use my modules?
   - No, just personal use?

---

## Next Steps

Once you answer the questions above, I can:

1. Create detailed implementation plan
2. Provide complete code examples
3. Create migration checklist
4. Write tests for each phase
5. Document any breaking changes

Let me know your preferences!

---

## ADDENDUM: Auto-Discovery of Modules (Updated 2026-01-21)

### Question: Do you have to manually expose modules one by one?

**Short answer: NO! You have several options for automatic module discovery:**

### Option 1: Using `import-tree` (Recommended, Simple)

**What**: Automatically imports all `.nix` files in a directory tree  
**Author**: [@vic](https://github.com/vic/import-tree)  
**Popularity**: 136 stars, used by drupol in their feature-based refactor

**Usage:**

```nix
# flake.nix
{
  inputs.import-tree.url = "github:vic/import-tree";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  
  outputs = inputs: 
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}
```

**For exposing modules:**

```nix
# flake-parts/modules.nix - Auto-expose all modules
{ inputs, lib, ... }:
let
  # Recursively find all .nix files in directories
  findModules = dir: 
    let
      entries = builtins.readDir dir;
      toModule = name: type:
        if type == "directory" 
        then findModules (dir + "/${name}")
        else if type == "regular" && lib.hasSuffix ".nix" name
        then { ${lib.removeSuffix ".nix" name} = dir + "/${name}"; }
        else {};
    in lib.foldl' lib.recursiveUpdate {} (lib.mapAttrsToList toModule entries);
in
{
  flake = {
    # Automatically expose all NixOS modules
    nixosModules = findModules ../modules/nixos/features;
    
    # Automatically expose all Darwin modules  
    darwinModules = findModules ../modules/darwin/features;
    
    # Or use import-tree directly
    nixosModules = inputs.import-tree.withLib lib {
      initFilter = lib.hasSuffix ".nix";
      addPath = ../modules/nixos/features;
      files = true;
    };
  };
}
```

**Pros:**
- ✅ Simple, works immediately
- ✅ Battle-tested (used by drupol, mightyiam)
- ✅ Ignores `/_` prefixed directories by default
- ✅ Extensible filter API

**Cons:**
- ⚠️ Imports ALL files (no selective exposure)
- ⚠️ No transformation/naming control

---

### Option 2: Using `haumea` (Advanced, Full Control)

**What**: Filesystem-based module system with transformers  
**Repo**: [nix-community/haumea](https://github.com/nix-community/haumea)  
**Used by**: omnibus, other advanced configs

**Features:**
- Transform file paths to attribute names
- Filter which files to include
- Apply transformations to module contents
- Build hierarchical module trees

**Note**: More complex, steeper learning curve. drupol tried it but switched to import-tree for simplicity.

---

### Option 3: Using `flake-parts-auto` (Experimental)

**What**: Auto imports and exports modules from conventional directories  
**Repo**: [DavHau/flake-parts-auto](https://github.com/DavHau/flake-parts-auto)  
**Convention:**
- `modules/flake-parts/*.nix` → `flakeModules.*`
- `modules/nixos/*.nix` → `nixosModules.*`
- `modules/darwin/*.nix` → `darwinModules.*`

**Disadvantage**: All modules are both imported AND exported (no selective control)

---

### Option 4: Manual with Helper Function (Balanced)

**What**: Write a simple helper that auto-discovers but gives you control

```nix
# lib/modules.nix
{ lib }:
{
  # Discover modules in a directory
  discoverModules = dir:
    let
      entries = builtins.readDir dir;
      isNixFile = name: type: 
        type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix";
      toModule = name: {
        name = lib.removeSuffix ".nix" name;
        value = dir + "/${name}";
      };
    in
      lib.listToAttrs (
        map toModule (
          lib.filter (name: isNixFile name entries.${name}) 
            (builtins.attrNames entries)
        )
      );
}
```

**Usage:**

```nix
# flake-parts/modules.nix
{ lib, ... }:
let
  moduleHelpers = import ../lib/modules.nix { inherit lib; };
in
{
  flake.nixosModules = moduleHelpers.discoverModules ../modules/nixos/features;
  flake.darwinModules = moduleHelpers.discoverModules ../modules/darwin/features;
}
```

**Pros:**
- ✅ Full control over discovery logic
- ✅ No external dependencies
- ✅ Easy to customize
- ✅ Can add filtering/transformation

**Cons:**
- ⚠️ Have to maintain the helper
- ⚠️ Doesn't handle nested directories (unless you add recursion)

---

### Option 5: pkgs-by-name-for-flake-parts (For Packages)

**What**: Specifically for auto-loading packages (not modules)  
**Repo**: [drupol/pkgs-by-name-for-flake-parts](https://github.com/drupol/pkgs-by-name-for-flake-parts)

Transforms a directory tree of package files into nested derivation attributes.

**Not applicable for your use case** (you need module discovery, not package discovery)

---

## Recommended Approach for Your Config

### Phase 2 Updated: Semi-Automatic Module Exposure

**Recommendation**: Use **Option 4 (Manual with Helper)** for now, consider **Option 1 (import-tree)** later

**Why:**
1. You already have `filesIn` in your lib - extend it!
2. Gives you control over what gets exposed
3. No new dependencies initially
4. Can migrate to import-tree later if desired

**Implementation:**

```nix
# lib/default.nix - Add to your existing lib
{
  # ... existing functions ...
  
  # New: Discover modules and create attrset
  modulesFrom = dir:
    let
      files = filesIn dir;
      toAttr = path: {
        name = fileNameOf path;
        value = path;
      };
    in
      lib.listToAttrs (map toAttr files);
}
```

```nix
# flake-parts/modules.nix
{ lib, ... }:
let
  myLib = import ../lib/default.nix { 
    inherit overlays nixpkgs inputs; 
  };
in
{
  flake = {
    # Auto-discover and expose NixOS feature modules
    nixosModules = lib.recursiveUpdate
      {
        # Manually expose important ones
        default = ../modules/nixos;
      }
      (myLib.modulesFrom ../modules/nixos/features);
    
    # Auto-discover Darwin modules
    darwinModules = lib.recursiveUpdate
      {
        default = ../modules/darwin;
      }
      (myLib.modulesFrom ../modules/darwin/features);
    
    # Home Manager modules
    homeManagerModules = {
      default = ../modules/home-manager;
      # Could auto-discover here too if desired
    };
  };
}
```

**Result:**

Others can use your modules like:

```nix
# Someone else's flake
{
  inputs.your-config.url = "github:zhongjis/nix-config";
  
  outputs = { nixpkgs, your-config, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules = [
        your-config.nixosModules.hyprland
        your-config.nixosModules.docker
        your-config.nixosModules.kubernetes
        # etc
      ];
    };
  };
}
```

**Timeline**: Add 30 minutes to Phase 2 (total 2.5-3 hours)

---

## The Dendritic Pattern (Advanced Alternative)

**What**: Every file is a flake-parts module  
**Originated by**: [@mightyiam](https://github.com/mightyiam/dendritic)  
**Adopted by**: [@drupol](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/), [@vic](https://github.com/vic/import-tree)

**Core Idea**: Think in "features" not "hosts"

```nix
# modules/features/desktop.nix - A flake-parts module
{ config, lib, pkgs, ... }:
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    services.xserver.enable = true;
    services.pipewire.enable = true;
  };
  
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [ firefox ];
  };
}
```

**Analysis for Your Config:**

**Don't Do This Yet:**
- ⚠️ Complete restructure required
- ⚠️ Your `extendModules` pattern is MORE convenient than Dendritic
- ⚠️ Dendritic loses automatic enable options
- ⚠️ Better for greenfield, not migration

**Your Current Pattern (Keep It!):**

```nix
# modules/nixos/features/docker.nix
{ pkgs, ... }:
{
  virtualisation.docker.enable = true;
  # Just the config, extendModules adds the enable option
}
```

```nix
# hosts/framework-16/configuration.nix
{
  myNixOS.docker.enable = true;  # Auto-generated by extendModules!
}
```

**This is BETTER than Dendritic for your use case** because:
- ✅ Automatic enable options
- ✅ mkIf wrapping handled automatically
- ✅ Less boilerplate
- ✅ Easier to enable/disable features per host

**When to Consider Dendritic:**
- You want to publish highly reusable modules
- You need cross-cutting concerns (same feature across nixos/home/darwin)
- You're starting fresh (not migrating)

---

## Updated Phase 2 Recommendation

### Before (Original Proposal)

```nix
# Manual exposure
flake.nixosModules = {
  hyprland = ../modules/nixos/features/hyprland.nix;
  docker = ../modules/nixos/features/docker.nix;
  kubernetes = ../modules/nixos/features/kubernetes.nix;
  # ... list all 15+ modules manually
};
```

### After (Updated with Auto-Discovery)

**Option A: Simple helper (Recommended)**

```nix
# flake-parts/modules.nix
{ lib, ... }:
let
  myLib = import ../lib/default.nix { inherit overlays nixpkgs inputs; };
in
{
  flake = {
    nixosModules = lib.recursiveUpdate
      { default = ../modules/nixos; }
      (myLib.modulesFrom ../modules/nixos/features);
    
    darwinModules = lib.recursiveUpdate
      { default = ../modules/darwin; }
      (myLib.modulesFrom ../modules/darwin/features);
  };
}
```

**Option B: import-tree (Alternative)**

```nix
# flake-parts/modules.nix
{ inputs, lib, ... }:
{
  flake = {
    nixosModules = 
      { default = ../modules/nixos; }
      // (lib.listToAttrs (
        map (path: {
          name = lib.removeSuffix ".nix" (baseNameOf path);
          value = path;
        }) (inputs.import-tree.withLib lib (
          inputs.import-tree.addPath ../modules/nixos/features
        ).files)
      ));
  };
}
```

---

## Summary: Module Exposure Options

| Option | Complexity | Control | Dependencies | Recommendation |
|--------|-----------|---------|--------------|----------------|
| Manual listing | Low | Full | None | ❌ Too tedious |
| Helper function | Low | Full | None | ✅ **Best for you** |
| import-tree | Medium | Medium | 1 input | ✅ Good alternative |
| haumea | High | Full | 1 input | ⚠️ Overkill |
| flake-parts-auto | Low | Low | 1 input | ⚠️ Too opinionated |
| Dendritic pattern | Very High | Full | None | ❌ Don't migrate to this |

---

## Updated Minimal Migration Path

**Phase 1: Foundation** (1-2 hours)
- Adopt flake-parts structure
- Move packages to perSystem
- Keep mkSystem/mkHome

**Phase 2: Auto-Discovered Module Publishing** (2.5-3 hours)
- ✅ Add `modulesFrom` helper to lib/
- ✅ Auto-expose nixosModules
- ✅ Auto-expose darwinModules  
- ✅ Manually expose homeManagerModules

**Total: 4-5 hours** (slightly more than original estimate)

**Result:**
- All features automatically exposed as modules
- Others can import: `inputs.your-config.nixosModules.docker`
- No manual maintenance of module lists
- Keep your excellent extendModules pattern

---

## Code Example: Complete Auto-Discovery

```nix
# lib/default.nix - Add these functions
{
  # ... existing functions (mkSystem, mkHome, etc) ...
  
  # New: Auto-discover modules in a directory
  modulesFrom = dir:
    let
      files = filesIn dir;
      toAttr = path: {
        name = fileNameOf path;
        value = path;
      };
    in
      inputs.nixpkgs.lib.listToAttrs (map toAttr files);
  
  # New: Recursively discover modules (includes subdirectories)
  modulesFromRecursive = dir:
    let
      entries = builtins.readDir dir;
      processEntry = name: type:
        let path = dir + "/${name}"; in
        if type == "directory"
        then modulesFromRecursive path
        else if type == "regular" && inputs.nixpkgs.lib.hasSuffix ".nix" name
        then { ${fileNameOf path} = path; }
        else {};
    in
      inputs.nixpkgs.lib.foldl' 
        inputs.nixpkgs.lib.recursiveUpdate 
        {} 
        (inputs.nixpkgs.lib.mapAttrsToList processEntry entries);
}
```

```nix
# flake-parts/modules.nix
{ lib, ... }:
let
  myLib = import ../lib/default.nix { 
    inherit overlays nixpkgs inputs; 
  };
in
{
  flake = {
    # Auto-expose all NixOS features
    nixosModules = lib.recursiveUpdate
      {
        default = ../modules/nixos;
        # Can still manually add special ones
        bundles = {
          general-desktop = ../modules/nixos/bundles/general-desktop.nix;
          developer = ../modules/nixos/bundles/developer.nix;
          gaming = ../modules/nixos/bundles/gaming.nix;
        };
      }
      {
        features = myLib.modulesFrom ../modules/nixos/features;
        services = myLib.modulesFrom ../modules/nixos/services;
      };
    
    # Auto-expose all Darwin modules
    darwinModules = lib.recursiveUpdate
      {
        default = ../modules/darwin;
        bundles = myLib.modulesFrom ../modules/darwin/bundles;
      }
      {
        features = myLib.modulesFrom ../modules/darwin/features;
      };
    
    # Home Manager - can be manual for now
    homeManagerModules = {
      default = ../modules/home-manager;
    };
  };
}
```

**Usage by others:**

```nix
{
  inputs.zshen-config.url = "github:zhongjis/nix-config";
  
  outputs = { nixpkgs, zshen-config, ... }: {
    nixosConfigurations.my-laptop = nixpkgs.lib.nixosSystem {
      modules = [
        # Use your entire bundle
        zshen-config.nixosModules.bundles.general-desktop
        
        # Or cherry-pick features
        zshen-config.nixosModules.features.docker
        zshen-config.nixosModules.features.kubernetes
        zshen-config.nixosModules.services.ollama
      ];
    };
  };
}
```

---

## Conclusion

**Answer to your question**: NO, you do NOT have to manually expose modules!

**Best approach for your config**:
1. Extend your existing `lib/` with `modulesFrom` helper
2. Use it in Phase 2 to auto-expose modules
3. Keep your extendModules pattern (it's excellent!)
4. Don't pursue Dendritic pattern (your current setup is better for your use case)

**Total effort**: 4-5 hours for Phases 1+2 with auto-discovery

Let me know if you want me to implement this updated approach!
