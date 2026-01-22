# Flake-Parts Migration Proposal (UPDATED - Using import-tree)

**Updated**: 2026-01-21  
**Primary Approach**: Use `import-tree` for automatic module discovery

---

## Executive Summary

This proposal outlines a phased migration strategy to adopt `flake-parts` and replace custom `lib/` utilities with flake-parts built-in methods. The migration preserves your existing modular architecture while gaining the benefits of the NixOS module system for flake organization.

**Key Goals:**
1. Replace `forAllSystems` with `perSystem` (straightforward win)
2. Adopt flake-parts module system for better organization
3. **Use `import-tree` for automatic module discovery and exposure**
4. Reduce custom glue code where flake-parts provides equivalent functionality
5. Preserve your battle-tested `extendModules` pattern (it's valuable!)

**Decision**: Use **import-tree** for Phase 2 (module publishing)
- Battle-tested (drupol, mightyiam, vic use it in production)
- Simple API, works immediately
- No custom helper code to maintain
- 136 GitHub stars, active maintenance

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

### What import-tree Provides

**Automatic module discovery:**
- Recursively imports all `.nix` files in a directory
- Ignores `/_` prefixed paths by default
- Simple, extensible filter API
- Can be used for both importing and exposing modules

**Key Benefits:**
1. **No Manual Maintenance**: Add/remove files, they're auto-discovered
2. **Battle-Tested**: Used in production by multiple major configs
3. **Simple API**: Works immediately, no complex setup
4. **Flexible**: Can filter, transform, or customize discovery

---

## Migration Strategy

### Phase 1: Foundation (Low Risk, High Value)

**Objective**: Adopt flake-parts structure without breaking existing functionality

**Changes:**
1. ✅ You already have `flake-parts` in inputs!
2. **Add `import-tree` to inputs**
3. Wrap `outputs` with `flake-parts.lib.mkFlake`
4. Define `systems` list
5. Move `packages` to `perSystem`
6. Keep `mkSystem` and `mkHome` in `flake` attribute for now

**Example:**

```nix
# flake.nix
{
  description = "Nixos config flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";  # NEW!
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
        ./flake-parts/modules.nix      # NEW!
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

**Impact:**
- ✅ Simple, low-risk change
- ✅ Immediately gain perSystem benefits
- ✅ No changes to modules or hosts
- ✅ Can iterate from here

**Timeline**: 1-2 hours

---

### Phase 2: Auto-Discovered Module Publishing with import-tree (High Value)

**Objective**: Use import-tree to automatically expose all reusable modules

**Changes:**

1. **Add import-tree input** (done in Phase 1)
2. **Create module exposure using import-tree**

```nix
# flake-parts/modules.nix
{ inputs, lib, ... }:
let
  # Helper to convert import-tree file list to module attrset
  filesToModules = files:
    lib.listToAttrs (
      map (path: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf path);
        value = path;
      }) files
    );
  
  # Get import-tree with lib loaded
  tree = inputs.import-tree.withLib lib;
in
{
  flake = {
    # Auto-expose all NixOS modules
    nixosModules = {
      # Default exports the entire nixos module system
      default = ../modules/nixos;
      
      # Auto-discovered bundles
      bundles = filesToModules (
        tree.addPath ../modules/nixos/bundles |> tree.files
      );
      
      # Auto-discovered features
      features = filesToModules (
        tree.addPath ../modules/nixos/features |> tree.files
      );
      
      # Auto-discovered services
      services = filesToModules (
        tree.addPath ../modules/nixos/services |> tree.files
      );
    };
    
    # Auto-expose all Darwin modules
    darwinModules = {
      default = ../modules/darwin;
      
      bundles = filesToModules (
        tree.addPath ../modules/darwin/bundles |> tree.files
      );
      
      features = filesToModules (
        tree.addPath ../modules/darwin/features |> tree.files
      );
    };
    
    # Home Manager modules - can be manual or auto-discovered
    homeManagerModules = {
      default = ../modules/home-manager;
      # Could add auto-discovery here too if desired
    };
  };
}
```

**Alternative: Simpler nested structure**

```nix
# flake-parts/modules.nix - Alternative simpler approach
{ inputs, lib, ... }:
let
  tree = inputs.import-tree.withLib lib;
  
  # Convert directory to flat module list
  discoverModules = dir:
    let files = (tree.addPath dir).files;
    in lib.listToAttrs (
      map (path: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf path);
        value = path;
      }) files
    );
in
{
  flake.nixosModules = 
    { default = ../modules/nixos; }
    // discoverModules ../modules/nixos/features
    // discoverModules ../modules/nixos/bundles
    // discoverModules ../modules/nixos/services;
  
  flake.darwinModules =
    { default = ../modules/darwin; }
    // discoverModules ../modules/darwin/features
    // discoverModules ../modules/darwin/bundles;
  
  flake.homeManagerModules = {
    default = ../modules/home-manager;
  };
}
```

**Usage by others:**

```nix
# Someone else's flake
{
  inputs.zshen-config.url = "github:zhongjis/nix-config";
  
  outputs = { nixpkgs, zshen-config, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules = [
        # Use individual features (auto-discovered!)
        zshen-config.nixosModules.hyprland
        zshen-config.nixosModules.docker
        zshen-config.nixosModules.kubernetes
        
        # Or use nested structure
        zshen-config.nixosModules.features.hyprland
        zshen-config.nixosModules.bundles.general-desktop
        zshen-config.nixosModules.services.ollama
      ];
    };
  };
}
```

**Benefits:**
- ✅ No manual module listing
- ✅ Add/remove files, automatically reflected
- ✅ Others can use your modules easily
- ✅ Better documentation of public API
- ✅ Can use in templates

**Impact:**
- ✅ Enables code reuse across repos
- ✅ Documents your module structure
- ✅ Zero maintenance overhead

**Timeline**: 1.5-2 hours

---

### Phase 3: Overlays in flake-parts (Optional, Low Value)

**Objective**: Expose overlays through flake-parts for consistency

**Changes:**

```nix
# flake-parts/overlays.nix
{ inputs, ... }:
{
  flake.overlays = import ../overlays { inherit inputs; };
}
```

**Analysis:**
- Your current overlay setup is already clean
- This just makes it accessible via flake-parts
- Minimal benefit, but good for consistency

**Timeline**: 15 minutes

---

### Phase 4: Simplify mkSystem/mkHome (NOT RECOMMENDED)

**Objective**: Reduce custom code in mkSystem/mkHome

**Analysis:**
- ⚠️ More verbose than current mkSystem
- ⚠️ Repeats overlay/module configuration per host
- ⚠️ Loses the clean abstraction you have

**Recommendation:**
- **KEEP mkSystem/mkHome** - they're excellent abstractions!
- Only migrate if you want maximum flake-parts purity
- Not worth the effort for minimal gain

**Timeline**: N/A (skip this phase)

---

## What to Keep from Your Custom lib/

### ✅ KEEP These (They're Great!)

1. **extendModules pattern**
   - Automatically creates enable options
   - Wraps configs with mkIf conditions
   - This is genuinely valuable, not replaceable by flake-parts or import-tree
   
2. **filesIn / dirsIn / fileNameOf**
   - Still useful internally
   - import-tree provides alternative but yours work fine
   
3. **mkSystem / mkHome**
   - Excellent abstractions that encapsulate complexity
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
- ✅ Phase 2 (Module Publishing with import-tree) - Pure additions, no behavior changes
- ✅ Phase 3 (Overlays) - Pure additions

### Medium Risk Changes
- ⚠️ Replacing special args - Requires module updates (NOT in this plan)

### High Risk Changes
- ❌ Phase 4 (Simplify mkSystem) - Not recommended
- ❌ Feature-based refactor - Complete reorg (NOT in this plan)

---

## Recommended Path Forward

### Minimal Migration (Recommended)

**Do this:**
1. ✅ Phase 1: Adopt flake-parts structure + add import-tree
2. ✅ Phase 2: Auto-discover and publish modules with import-tree
3. ✅ Phase 3 (optional): Expose overlays
4. ✅ Replace `forAllSystems` with `perSystem`
5. ✅ Keep everything else as-is

**Result:**
- Best of both worlds
- Gain flake-parts benefits without losing custom abstractions
- Automatic module discovery and publishing
- Can iterate further if desired

**Time investment**: 3-4 hours
**Risk**: Very Low
**Reward**: High (immediate perSystem benefits + auto module publishing)

---

## Example: Complete Migration Result

Here's what your flake would look like after Phases 1-3:

```nix
# flake.nix
{
  description = "Nixos config flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    
    # ... all your other inputs (home-manager, nix-darwin, etc.)
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
{ inputs, lib, ... }:
let
  tree = inputs.import-tree.withLib lib;
  
  # Helper to discover and convert to attrset
  discoverModules = dir:
    let files = (tree.addPath dir).files;
    in lib.listToAttrs (
      map (path: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf path);
        value = path;
      }) files
    );
in
{
  flake = {
    # NixOS modules - auto-discovered
    nixosModules = 
      { default = ../modules/nixos; }
      // discoverModules ../modules/nixos/features
      // discoverModules ../modules/nixos/bundles
      // discoverModules ../modules/nixos/services;
    
    # Darwin modules - auto-discovered
    darwinModules =
      { default = ../modules/darwin; }
      // discoverModules ../modules/darwin/features
      // discoverModules ../modules/darwin/bundles;
    
    # Home Manager modules
    homeManagerModules = {
      default = ../modules/home-manager;
    };
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
- ✅ import-tree for automatic module discovery
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

### Phase 2 Testing

```bash
# Verify modules are exposed
nix flake show | grep -A 20 "nixosModules"
nix flake show | grep -A 20 "darwinModules"

# Expected output:
# nixosModules:
#   ├── default: NixOS module
#   ├── docker: NixOS module
#   ├── flatpak: NixOS module
#   ├── hyprland: NixOS module
#   └── ... (all your features/bundles/services)

# Test that a module can be imported
nix eval .#nixosModules.docker --apply 'x: "ok"'
nix eval .#nixosModules.hyprland --apply 'x: "ok"'

# Full rebuild test
nh os switch .       # NixOS
nh darwin switch .   # macOS
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

## Why import-tree Over Other Options?

### Comparison Matrix

| Criteria | import-tree | Helper Function | haumea | flake-parts-auto |
|----------|-------------|-----------------|--------|------------------|
| **Simplicity** | ✅ Very simple | ✅ Simple | ⚠️ Complex | ✅ Simple |
| **Maintenance** | ✅ None (external) | ⚠️ You maintain it | ✅ None | ✅ None |
| **Battle-tested** | ✅ Yes (production) | ❌ New code | ✅ Yes | ⚠️ Experimental |
| **Flexibility** | ✅ Filter API | ✅ Full control | ✅ Full control | ❌ Opinionated |
| **Dependencies** | 1 input | 0 | 1 input | 1 input |
| **Learning curve** | ✅ Minimal | ✅ Minimal | ❌ Steep | ✅ Minimal |
| **Community adoption** | ✅ Growing | N/A | ✅ Established | ❌ Low |

### Real-World Usage

**drupol (author of "Refactoring Infrastructure"):**
> "I wish I could have used Haumea for loading the modules, but after hours of trying, I couldn't get anywhere. I therefore used import-tree and in less than 5 minutes it was working."

**mightyiam (creator of Dendritic pattern):**
- Uses import-tree in production
- Pattern validated across multiple repos

**vic (author of import-tree):**
- Actively maintained
- Used in personal and professional configs
- Simple, extensible API

### Why Not Others?

**Helper Function:**
- ✅ No dependencies
- ❌ You have to maintain it
- ❌ Need to handle edge cases
- ❌ Reinventing the wheel

**haumea:**
- ✅ Very powerful
- ❌ Complex API
- ❌ Steep learning curve
- ❌ Overkill for simple use case

**flake-parts-auto:**
- ✅ Convention-based
- ❌ No selective control (imports AND exports everything)
- ❌ Less flexible
- ❌ Low adoption

---

## Community Resources

**Official Documentation:**
- [flake.parts](https://flake.parts/) - Official docs
- [import-tree](https://github.com/vic/import-tree) - Auto-import tool
- [flake.parts/options](https://flake.parts/options/flake-parts.html) - All options
- [Multi-platform guide](https://flake.parts/multi-platform)

**Real-World Examples:**
- [drupol/infra](https://github.com/drupol/infra) - Feature-based with import-tree
- [mightyiam/infra](https://github.com/mightyiam/infra) - Dendritic pattern
- [vic/vix](https://github.com/vic/vix) - import-tree usage
- [Mic92/dotfiles](https://github.com/Mic92/dotfiles) - Production NixOS+Darwin

**Community Articles:**
- [Refactoring Infrastructure](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/) - drupol's migration story
- [Dendritic Pattern](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271) - Discussion thread
- [Dendrix Documentation](https://vic.github.io/dendrix/) - Community conventions

**Community Modules:**
- [treefmt-nix](https://github.com/numtide/treefmt-nix) - Declarative formatting
- [pre-commit-hooks](https://github.com/cachix/pre-commit-hooks.nix) - Git hooks
- [devenv](https://github.com/cachix/devenv) - Dev environments

---

## Decision Summary

### ✅ What We're Doing

**Phase 1: Foundation (1-2 hours)**
- Add flake-parts structure
- Add import-tree input
- Move packages to perSystem
- Keep mkSystem/mkHome

**Phase 2: Auto Module Publishing (1.5-2 hours)**
- Use import-tree to auto-discover modules
- Expose nixosModules, darwinModules, homeManagerModules
- No manual maintenance

**Phase 3: Overlays (optional, 15 min)**
- Expose overlays through flake-parts

**Total: 3-4 hours**

### ✅ What We're Keeping

- extendModules pattern (automatic enable options)
- mkSystem/mkHome abstractions
- Special args (currentSystem, etc.)
- filesIn/dirsIn/fileNameOf helpers
- Your entire module organization

### ❌ What We're NOT Doing

- Feature-based refactor (Dendritic pattern)
- Replacing mkSystem/mkHome with verbose code
- Changing module structure
- Replacing special args
- Breaking any existing functionality

---

## Next Steps

Once you approve this plan, I will:

1. Create detailed step-by-step implementation checklist
2. Provide complete code for each flake-parts module
3. Write migration script if needed
4. Document testing procedures
5. Create rollback instructions

**Questions to confirm:**

1. ✅ Use import-tree for auto-discovery? **[CONFIRMED]**
2. Timeline acceptable (3-4 hours)?
3. Keep mkSystem/mkHome? (Recommended: YES)
4. Keep extendModules? (Recommended: YES)
5. Any specific modules you want to exclude from publishing?

---

## Conclusion

**This migration will:**
- ✅ Replace forAllSystems with perSystem (cleaner multi-system)
- ✅ Automatically discover and expose all modules (no manual lists)
- ✅ Enable others to use your excellent modules
- ✅ Reduce custom glue code where appropriate
- ✅ Keep your battle-tested patterns (extendModules, mkSystem)

**Time investment**: 3-4 hours  
**Risk level**: Very Low  
**Value delivered**: High  

Ready to proceed when you are! 🚀
