# Home-Manager Module Refactoring - Visual Guide

## Current Structure (BEFORE)

```
modules/
├── home-manager/               (shared, cross-platform)
│   ├── default.nix             [auto-imports via filesIn ./.]
│   ├── alacritty.nix           FEATURE
│   ├── git.nix                 FEATURE
│   ├── tmux/                   FEATURE (should be SERVICE)
│   │   └── default.nix
│   ├── bundle-general.nix      BUNDLE
│   ├── bundle-office.nix       BUNDLE
│   └── ... (20 files, 8 subdirs, 3 bundles)
│
├── home-manager-linux/         (Linux-specific)
│   ├── default.nix             [auto-imports via filesIn ./.]
│   ├── distrobox.nix           FEATURE
│   ├── dunst.nix               SERVICE
│   ├── hypridle.nix            SERVICE
│   ├── waybar/                 SERVICE
│   │   └── default.nix
│   ├── hyprland/               FEATURE
│   │   └── default.nix
│   ├── bundle-hyprland.nix     BUNDLE
│   ├── bundle-linux.nix        BUNDLE
│   └── ... (6 files, 5 subdirs, 2 bundles)
│
└── home-manager-darwin/        (Darwin-specific)
    ├── default.nix             [auto-imports via filesIn ./.]
    ├── aerospace/              FEATURE
    │   └── default.nix
    └── bundle-darwin.nix       BUNDLE
```

## Target Structure (AFTER)

```
modules/
├── home-manager/               (shared, cross-platform)
│   ├── default.nix             [auto-imports via ./features, ./bundles, ./services]
│   ├── features/               NEW DIRECTORY
│   │   ├── alacritty.nix
│   │   ├── git.nix
│   │   ├── neovim/
│   │   │   └── default.nix
│   │   ├── zsh/
│   │   │   └── default.nix
│   │   └── ... (20 files, 6 subdirs)
│   ├── bundles/                NEW DIRECTORY
│   │   ├── general.nix         [renamed from bundle-general.nix]
│   │   ├── general-server.nix  [renamed from bundle-general-server.nix]
│   │   └── office.nix          [renamed from bundle-office.nix]
│   └── services/               NEW DIRECTORY
│       ├── tmux/               [moved from parent]
│       │   └── default.nix
│       └── wlogout/            [moved from parent]
│           └── default.nix
│
├── home-manager-linux/         (Linux-specific)
│   ├── default.nix             [auto-imports via ./features, ./bundles, ./services]
│   ├── features/               NEW DIRECTORY
│   │   ├── distrobox.nix
│   │   ├── hyprpaper.nix
│   │   ├── hyprland/
│   │   │   └── default.nix
│   │   ├── hyprlock/
│   │   │   └── default.nix
│   │   └── ... (4 files, 3 subdirs)
│   ├── bundles/                NEW DIRECTORY
│   │   ├── hyprland.nix        [renamed from bundle-hyprland.nix]
│   │   └── linux.nix           [renamed from bundle-linux.nix]
│   └── services/               NEW DIRECTORY
│       ├── dunst.nix
│       ├── hypridle.nix
│       ├── waybar/
│       │   └── default.nix
│       └── swaync/
│           └── default.nix
│
└── home-manager-darwin/        (Darwin-specific)
    ├── default.nix             [auto-imports via ./features, ./bundles, ./services]
    ├── features/               NEW DIRECTORY
    │   └── aerospace/
    │       └── default.nix
    ├── bundles/                NEW DIRECTORY
    │   └── darwin.nix          [renamed from bundle-darwin.nix]
    └── services/               NEW DIRECTORY (empty for now)
```

## Enable Option Paths

### BEFORE (Current System)

```nix
# Features (flat files)
myHomeManager.git.enable = true;
myHomeManager.alacritty.enable = true;
myHomeManager.tmux.enable = true;        # Will become .services.tmux

# Features (subdirectories)
myHomeManager.neovim.enable = true;
myHomeManager.zsh.enable = true;

# Linux Features
myHomeManager.distrobox.enable = true;
myHomeManager.hyprland.enable = true;
myHomeManager.dunst.enable = true;       # Will become .services.dunst
myHomeManager.hypridle.enable = true;    # Will become .services.hypridle

# Bundles (prefix stripped in current system)
myHomeManager.bundles.general.enable = true;
myHomeManager.bundles.linux.enable = true;
myHomeManager.bundles.hyprland.enable = true;
```

### AFTER (Refactored System)

```nix
# Features (in features/ subdirectory)
myHomeManager.git.enable = true;               # UNCHANGED
myHomeManager.alacritty.enable = true;         # UNCHANGED
myHomeManager.neovim.enable = true;            # UNCHANGED
myHomeManager.zsh.enable = true;               # UNCHANGED

# Linux Features (in features/ subdirectory)
myHomeManager.distrobox.enable = true;         # UNCHANGED
myHomeManager.hyprland.enable = true;          # UNCHANGED

# Services (in services/ subdirectory)
myHomeManager.services.tmux.enable = true;     # CHANGED: added .services
myHomeManager.services.wlogout.enable = true;  # CHANGED: added .services

# Linux Services (in services/ subdirectory)
myHomeManager.services.dunst.enable = true;    # CHANGED: added .services
myHomeManager.services.hypridle.enable = true; # CHANGED: added .services
myHomeManager.services.waybar.enable = true;   # CHANGED: added .services

# Bundles (in bundles/ subdirectory, no prefix)
myHomeManager.bundles.general.enable = true;       # UNCHANGED
myHomeManager.bundles.linux.enable = true;         # UNCHANGED
myHomeManager.bundles.hyprland.enable = true;      # UNCHANGED
```

## Key Changes Summary

### What Changes:
1. **File locations**: Modules move from flat structure to `features/`, `bundles/`, `services/` subdirectories
2. **Bundle filenames**: Strip `bundle-` prefix (e.g., `bundle-general.nix` → `general.nix`)
3. **Service enable paths**: Add `.services` namespace (e.g., `myHomeManager.tmux.enable` → `myHomeManager.services.tmux.enable`)
4. **default.nix logic**: Scan subdirectories instead of flat structure + prefix filtering

### What Stays the Same:
1. **Feature enable paths**: `myHomeManager.featureName.enable` (no `.services` prefix)
2. **Bundle enable paths**: `myHomeManager.bundles.bundleName.enable` (already have `.bundles` prefix)
3. **Module content**: No changes to the actual configuration logic inside modules
4. **Auto-import mechanism**: Same `extendModules` function, just different directory scanning

## Migration Impact

### Low Risk (No Changes Needed):
- Host configurations that only reference bundles ✓
- Features used directly (git, alacritty, etc.) ✓
- Complex features in subdirectories (neovim, zsh, etc.) ✓

### Medium Risk (Updates Required):
- Bundle files that enable services (need `.services` prefix) ⚠️
  - `bundle-general.nix` → references `tmux`
  - `bundle-hyprland.nix` → references `dunst`, `hypridle`, `waybar`

### High Risk (Careful Testing):
- default.nix files (logic changes) ⚠️⚠️⚠️
  - Must update to scan subdirectories
  - Must add services section
  - Critical for auto-import to work

## Testing Checklist

After refactoring, verify these enable paths work:

**Shared Features:**
- [ ] `myHomeManager.git.enable`
- [ ] `myHomeManager.neovim.enable`
- [ ] `myHomeManager.zsh.enable`

**Shared Services:**
- [ ] `myHomeManager.services.tmux.enable`
- [ ] `myHomeManager.services.wlogout.enable`

**Shared Bundles:**
- [ ] `myHomeManager.bundles.general.enable`
- [ ] `myHomeManager.bundles.office.enable`

**Linux Features:**
- [ ] `myHomeManager.hyprland.enable`
- [ ] `myHomeManager.distrobox.enable`

**Linux Services:**
- [ ] `myHomeManager.services.dunst.enable`
- [ ] `myHomeManager.services.hypridle.enable`
- [ ] `myHomeManager.services.waybar.enable`

**Linux Bundles:**
- [ ] `myHomeManager.bundles.linux.enable`
- [ ] `myHomeManager.bundles.hyprland.enable`

**Darwin Features:**
- [ ] `myHomeManager.aerospace.enable`

**Darwin Bundles:**
- [ ] `myHomeManager.bundles.darwin.enable`

