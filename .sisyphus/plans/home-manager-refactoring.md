# Home-Manager Module Refactoring Plan

## Overview
Refactor home-manager modules to follow the same structured organization pattern as NixOS and Darwin modules: separate subdirectories for `bundles/`, `services/`, and `features/`.

**Current State:**
- `modules/home-manager/` - flat structure with mixed bundles (prefixed `bundle-*`), features (individual `.nix` files), and complex modules (subdirectories)
- `modules/home-manager-linux/` - flat structure mixing bundles and features
- `modules/home-manager-darwin/` - flat structure mixing bundles and features

**Target State:**
- `modules/home-manager/{bundles,features,services}/` - organized subdirectories
- `modules/home-manager-linux/{bundles,features,services}/` - organized subdirectories  
- `modules/home-manager-darwin/{bundles,features,services}/` - organized subdirectories

**Pattern Reference:**
- NixOS: `modules/nixos/{bundles,features,services}/` ✓ (already structured)
- Darwin: `modules/darwin/{bundles,features}/` ✓ (already structured, no services)

## Research Findings

### Current Structure Analysis

**modules/home-manager/** (shared, cross-platform):
- **Bundles (3)**: `bundle-general.nix`, `bundle-general-server.nix`, `bundle-office.nix`
- **Features (20 files)**: `alacritty.nix`, `cht-sh.nix`, `direnv.nix`, `fastfetch.nix`, `fzf.nix`, `ghostty.nix`, `git.nix`, `gtk.nix`, `kitty.nix`, `kubernetes.nix`, `lazygit.nix`, `mcp.nix`, `rg.nix`, `sops.nix`, `starship.nix`, `stylix.nix`, `wezterm.nix`, `yazi.nix`, `zed.nix`, `zen-browser.nix`
- **Complex Features (8 subdirs)**: `claude-code/`, `neovim/`, `opencode/`, `ssh/`, `tmux/`, `wlogout/`, `zellij/`, `zsh/`
- **Services**: None currently categorized as services, but some features ARE services (e.g., `tmux` could be considered a service)

**modules/home-manager-linux/** (Linux-specific):
- **Bundles (2)**: `bundle-hyprland.nix`, `bundle-linux.nix`
- **Features (6 files)**: `distrobox.nix`, `dunst.nix`, `hypridle.nix`, `hyprpaper.nix`, `hyprsunset.nix`, `pipewire-noise-cancling-input.nix`
- **Complex Features (5 subdirs)**: `hyprland/`, `hyprlock/`, `rofi/`, `swaync/`, `waybar/`
- **Services**: Many of these ARE services (`dunst`, `hypridle`, `swaync`, `waybar`, etc.)

**modules/home-manager-darwin/** (Darwin-specific):
- **Bundles (1)**: `bundle-darwin.nix`
- **Features (1 subdir)**: `aerospace/`
- **Services**: None currently

### Auto-Import Mechanism

**Current (`modules/home-manager/default.nix`):**
```nix
# Scans ALL .nix files in current directory (flat)
allFiles = myLib.filesIn ./.;

# Separates by bundle- prefix
featureFiles = filter (not starts with "bundle-")
bundleFiles = filter (starts with "bundle-")

# Creates enable options:
# myHomeManager.${name}.enable (features)
# myHomeManager.bundles.${bundleName}.enable (bundles, strips prefix)
```

**Target Pattern (from `modules/nixos/default.nix`):**
```nix
# Scans specific subdirectories
features = myLib.extendModules (...) (myLib.filesIn ./features);
bundles = myLib.extendModules (...) (myLib.filesIn ./bundles);
services = myLib.extendModules (...) (myLib.filesIn ./services);

# Creates enable options:
# myNixOS.${name}.enable (features)
# myNixOS.bundles.${name}.enable (bundles, NO prefix needed)
# myNixOS.services.${name}.enable (services)
```

## Categorization Strategy

### What Goes Where?

**Features:**
- Program configurations (terminal emulators, editors, browsers)
- CLI tools and utilities
- Single-purpose modules that configure one thing
- Examples: `git.nix`, `fzf.nix`, `starship.nix`, `yazi.nix`

**Bundles:**
- Collections that enable multiple features/services
- Logical groupings (e.g., "general", "office", "hyprland")
- Examples: `bundle-general.nix` → `general.nix`, `bundle-hyprland.nix` → `hyprland.nix`

**Services:**
- Background daemons and system services
- Things that run continuously or respond to events
- Examples (Linux): `dunst.nix` (notifications), `hypridle.nix` (idle daemon), `swaync.nix` (notification center), `waybar.nix` (status bar)
- Note: Shared services are rare in home-manager (most are platform-specific)

## Detailed Refactoring Steps

### Phase 1: Create Directory Structure

1. **Create subdirectories in all three home-manager module locations:**
   ```bash
   mkdir -p modules/home-manager/{bundles,features,services}
   mkdir -p modules/home-manager-linux/{bundles,features,services}
   mkdir -p modules/home-manager-darwin/{bundles,features,services}
   ```

### Phase 2: Categorize and Move Files

**modules/home-manager/ (shared):**

Move to `features/`:
- `alacritty.nix`
- `cht-sh.nix`
- `direnv.nix`
- `fastfetch.nix`
- `fzf.nix`
- `ghostty.nix`
- `git.nix`
- `gtk.nix`
- `kitty.nix`
- `kubernetes.nix`
- `lazygit.nix`
- `mcp.nix`
- `rg.nix`
- `sops.nix`
- `starship.nix`
- `stylix.nix`
- `wezterm.nix`
- `yazi.nix`
- `zed.nix`
- `zen-browser.nix`
- `claude-code/` (entire directory)
- `neovim/` (entire directory)
- `opencode/` (entire directory)
- `ssh/` (entire directory)
- `zellij/` (entire directory)
- `zsh/` (entire directory)

Move to `services/`:
- `tmux/` (terminal multiplexer service)
- `wlogout/` (logout menu service)

Move to `bundles/`:
- `bundle-general.nix` → `general.nix` (rename, strip prefix)
- `bundle-general-server.nix` → `general-server.nix` (rename, strip prefix)
- `bundle-office.nix` → `office.nix` (rename, strip prefix)

**modules/home-manager-linux/ (Linux-specific):**

Move to `features/`:
- `distrobox.nix`
- `hyprpaper.nix` (wallpaper setter, one-shot tool)
- `hyprsunset.nix` (blue light filter, can be considered a feature)
- `pipewire-noise-cancling-input.nix`
- `hyprland/` (window manager - complex feature)
- `hyprlock/` (screen locker - feature)
- `rofi/` (launcher - feature)

Move to `services/`:
- `dunst.nix` (notification daemon)
- `hypridle.nix` (idle management daemon)
- `swaync/` (notification center daemon)
- `waybar/` (status bar daemon)

Move to `bundles/`:
- `bundle-hyprland.nix` → `hyprland.nix` (rename, strip prefix)
- `bundle-linux.nix` → `linux.nix` (rename, strip prefix)

**modules/home-manager-darwin/ (Darwin-specific):**

Move to `features/`:
- `aerospace/` (window manager)

Move to `bundles/`:
- `bundle-darwin.nix` → `darwin.nix` (rename, strip prefix)

### Phase 3: Update default.nix Files

**Update `modules/home-manager/default.nix`:**

```nix
{
  lib,
  config,
  myLib,
  ...
}: let
  cfg = config.myHomeManager;

  # Scan subdirectories instead of flat structure
  features =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.${name}.enable = lib.mkEnableOption "enable my ${name} configuration";
      };

      configExtension = config: (lib.mkIf cfg.${name}.enable config);
    })
    (myLib.filesIn ./features);

  # No more bundle- prefix stripping needed
  bundles =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.bundles.${name}.enable = lib.mkEnableOption "enable ${name} module bundle";
      };

      configExtension = config: (lib.mkIf cfg.bundles.${name}.enable config);
    })
    (myLib.filesIn ./bundles);

  # NEW: Add services support
  services =
    myLib.extendModules
    (name: {
      extraOptions = {
        myHomeManager.services.${name}.enable = lib.mkEnableOption "enable ${name} service";
      };

      configExtension = config: (lib.mkIf cfg.services.${name}.enable config);
    })
    (myLib.filesIn ./services);
in {
  imports =
    []
    ++ features
    ++ bundles
    ++ services; # NEW

  xdg.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
      experimental-features = "nix-command flakes";
    };
  };

  programs.home-manager.enable = true;
}
```

**Update `modules/home-manager-linux/default.nix`:**
- Same pattern as above (add `features`, `bundles`, `services` subdirectory scanning)

**Update `modules/home-manager-darwin/default.nix`:**
- Same pattern as above (add `features`, `bundles`, `services` subdirectory scanning)

### Phase 4: Update Bundle References

After renaming bundles (stripping `bundle-` prefix), update any references in host configurations:

**Check these files:**
- `hosts/framework-16/home.nix`
- `hosts/mac-m1-max/home.nix`
- Any bundle files that reference other bundles

**Example change:**
```nix
# BEFORE
myHomeManager.bundles.general.enable = true;  # Already correct (prefix was stripped)

# AFTER (no change needed - option name stays the same)
myHomeManager.bundles.general.enable = true;
```

The option names **won't change** because the current system already strips the `bundle-` prefix. We're just moving files to match the new structure.

### Phase 5: Testing Strategy

1. **Pre-move validation:**
   ```bash
   # Check current system builds
   nix flake check
   ```

2. **Move files in batches:**
   - First batch: Move bundles only
   - Second batch: Move simple features
   - Third batch: Move complex features (subdirectories)
   - Fourth batch: Move services

3. **After each batch:**
   ```bash
   # Verify flake still evaluates
   nix flake check
   
   # Test build without switching
   nix build .#homeConfigurations."zshen@framework-16".activationPackage
   nix build .#homeConfigurations."zshen@Zhongjies-MacBook-Pro.local".activationPackage
   ```

4. **Final validation:**
   ```bash
   # Build and switch on both systems
   # Linux:
   nh os switch .
   
   # Darwin:
   nh darwin switch .
   ```

## Benefits of Refactoring

1. **Consistency**: All module systems (NixOS, Darwin, home-manager) follow the same pattern
2. **Clarity**: Clear separation of concerns (features vs bundles vs services)
3. **Maintainability**: Easier to find and organize modules as the config grows
4. **No prefix needed**: Bundles no longer need `bundle-` prefix in filenames
5. **Scalability**: Clear guidelines for where new modules should go

## Potential Issues and Mitigations

### Issue 1: Breaking Changes
**Risk**: Moving files might break imports if anything references them directly
**Mitigation**: The auto-import system means nothing should reference files directly. All references are via enable options which won't change.

### Issue 2: Git History
**Risk**: `git mv` might lose file history tracking
**Mitigation**: Use `git mv` instead of `mv` to preserve history. Git is smart enough to track moves.

### Issue 3: Complex Modules with Subdirectories
**Risk**: Moving subdirectories like `neovim/` might be tricky
**Mitigation**: `myLib.filesIn` recursively scans, so moving entire directories should work. The `default.nix` in each subdir will still be found.

### Issue 4: Service Classification
**Risk**: Disagreement about what's a "service" vs "feature"
**Mitigation**: Follow this heuristic:
- **Service**: Runs continuously in background, responds to events, provides daemon functionality
- **Feature**: Configures a program/tool, may be invoked by user or other programs

## Timeline Estimate

- **Phase 1** (Create directories): 5 minutes
- **Phase 2** (Categorize and move): 30-45 minutes
  - Shared modules: ~15 minutes
  - Linux modules: ~15 minutes
  - Darwin modules: ~5 minutes
  - Verification: ~10 minutes
- **Phase 3** (Update default.nix): 20 minutes
- **Phase 4** (Update references): 10 minutes (likely no changes needed)
- **Phase 5** (Testing): 20-30 minutes

**Total**: ~1.5 to 2 hours

## Success Criteria

- [ ] All three home-manager module locations have `bundles/`, `features/`, and `services/` subdirectories
- [ ] All modules are correctly categorized and moved
- [ ] All bundle files are renamed (strip `bundle-` prefix)
- [ ] All three `default.nix` files updated to scan subdirectories
- [ ] `nix flake check` passes
- [ ] Both home-manager configurations build successfully
- [ ] System switches successfully on both Linux and Darwin
- [ ] All previously enabled features/bundles still work

## Post-Refactoring Documentation

Update `AGENTS.md` to reflect new structure:
- Update "File Organization" section
- Update "Module Guidelines" section
- Add examples showing the new subdirectory structure
- Document the categorization heuristics (what goes where)

## Notes

- This refactoring is **purely organizational** - no functionality changes
- Enable option paths remain **unchanged** (e.g., `myHomeManager.git.enable`)
- The auto-import system via `extendModules` makes this refactoring safe
- Bundle option paths remain **unchanged** (prefix already stripped by current system)

---

## ADDENDUM: Files Requiring Updates After Service Categorization

Based on grep search for references to modules being moved to `services/`:

### Bundle Files to Update

**`modules/home-manager/bundle-general.nix`:**
```nix
# BEFORE
myHomeManager.tmux.enable = lib.mkDefault true;

# AFTER
myHomeManager.services.tmux.enable = lib.mkDefault true;
```

**`modules/home-manager-linux/bundle-hyprland.nix`:**
```nix
# BEFORE
myHomeManager.hypridle.enable = true;
myHomeManager.dunst.enable = true;
myHomeManager.waybar.enable = true;
# myHomeManager.wlogout.enable = true;  # commented
# myHomeManager.swaync.enable = true;   # commented

# AFTER
myHomeManager.services.hypridle.enable = true;
myHomeManager.services.dunst.enable = true;
myHomeManager.services.waybar.enable = true;
# myHomeManager.services.wlogout.enable = true;  # commented
# myHomeManager.services.swaync.enable = true;   # commented
```

### Host Configurations

**NO CHANGES NEEDED** for host configurations:
- `hosts/framework-16/home.nix` - only references bundles
- `hosts/mac-m1-max/home.nix` - only references bundles

### default.nix Files

Already covered in Phase 3 - these need to add the `services` section.

### Summary of Required Changes

**Phase 4 Update**: In addition to checking host configurations, update these 2 bundle files:

1. `modules/home-manager/bundles/general.nix` (after moving)
   - Change `myHomeManager.tmux.enable` → `myHomeManager.services.tmux.enable`

2. `modules/home-manager-linux/bundles/hyprland.nix` (after moving)
   - Change `myHomeManager.hypridle.enable` → `myHomeManager.services.hypridle.enable`
   - Change `myHomeManager.dunst.enable` → `myHomeManager.services.dunst.enable`
   - Change `myHomeManager.waybar.enable` → `myHomeManager.services.waybar.enable`
   - Update commented lines too: `wlogout` and `swaync`

**Total files requiring manual edits**: 2 bundle files + 3 default.nix files = **5 files**

