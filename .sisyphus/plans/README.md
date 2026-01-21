# Home-Manager Module Refactoring Plans

This directory contains comprehensive planning documents for refactoring home-manager modules to follow a structured organization pattern consistent with NixOS and Darwin modules.

## Quick Links

1. **[home-manager-refactoring.md](./home-manager-refactoring.md)** - Main refactoring plan with detailed analysis, strategy, and phases
2. **[home-manager-refactoring-visual.md](./home-manager-refactoring-visual.md)** - Visual guide showing before/after structure and migration paths
3. **[home-manager-refactoring-commands.md](./home-manager-refactoring-commands.md)** - Step-by-step implementation commands (ready to execute)

## Overview

**Goal**: Organize home-manager modules into `bundles/`, `features/`, and `services/` subdirectories to match the existing NixOS and Darwin module patterns.

**Scope**: 
- 3 module locations: `modules/home-manager/`, `modules/home-manager-linux/`, `modules/home-manager-darwin/`
- ~50 total files to move/rename
- 5 files requiring manual edits
- 0 changes to host configurations (enable paths mostly stay the same)

**Impact**:
- ✅ Features: Enable paths unchanged (e.g., `myHomeManager.git.enable`)
- ✅ Bundles: Enable paths unchanged (e.g., `myHomeManager.bundles.general.enable`)
- ⚠️ Services: Enable paths change to add `.services` namespace (e.g., `myHomeManager.tmux.enable` → `myHomeManager.services.tmux.enable`)

## Recommended Reading Order

1. **Start here**: [home-manager-refactoring-visual.md](./home-manager-refactoring-visual.md) - Get a visual understanding of the changes
2. **Deep dive**: [home-manager-refactoring.md](./home-manager-refactoring.md) - Understand the rationale, risks, and detailed strategy
3. **Execute**: [home-manager-refactoring-commands.md](./home-manager-refactoring-commands.md) - Copy/paste commands to implement

## Key Decisions

### Categorization Heuristic

**Features** → Programs, tools, configurations
- Examples: `git.nix`, `neovim/`, `alacritty.nix`
- Enable: `myHomeManager.<name>.enable`

**Services** → Background daemons, continuous processes
- Examples: `tmux/`, `dunst.nix`, `waybar/`
- Enable: `myHomeManager.services.<name>.enable`

**Bundles** → Collections enabling multiple features/services
- Examples: `general.nix`, `hyprland.nix`, `office.nix`
- Enable: `myHomeManager.bundles.<name>.enable`

### File Moves Summary

| Location | Features | Services | Bundles |
|----------|----------|----------|---------|
| `modules/home-manager/` | 26 items | 2 items | 3 items |
| `modules/home-manager-linux/` | 7 items | 4 items | 2 items |
| `modules/home-manager-darwin/` | 1 item | 0 items | 1 item |
| **Total** | **34** | **6** | **6** |

### Manual Edits Required

1. `modules/home-manager/default.nix` - Update to scan subdirectories
2. `modules/home-manager-linux/default.nix` - Update to scan subdirectories
3. `modules/home-manager-darwin/default.nix` - Update to scan subdirectories
4. `modules/home-manager/bundles/general.nix` - Update tmux reference to use `.services`
5. `modules/home-manager-linux/bundles/hyprland.nix` - Update service references to use `.services`

## Benefits

1. **Consistency** - All module systems follow the same pattern
2. **Clarity** - Clear separation of concerns (features vs bundles vs services)
3. **Maintainability** - Easier to find and organize modules
4. **Scalability** - Clear guidelines for adding new modules
5. **Clean filenames** - Bundles no longer need `bundle-` prefix

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Breaking imports | Low | Auto-import system means no direct file imports |
| Git history loss | Low | Use `git mv` to preserve history |
| Service misclassification | Low | Clear heuristics provided |
| Build failures | Medium | Batch testing after each phase |
| Runtime issues | Low | Rollback plan with backup branch |

## Timeline

- **Total estimated time**: 1-2 hours
- **Phases**: 5 (create dirs → move files → update code → test → commit)
- **Risk level**: Low-Medium (organizational refactor, no logic changes)

## Success Criteria

- [ ] All modules organized into subdirectories
- [ ] Bundle files renamed (strip `bundle-` prefix)
- [ ] default.nix files updated
- [ ] Bundle references updated
- [ ] `nix flake check` passes
- [ ] Both home-manager configs build
- [ ] System switches successfully
- [ ] All enabled features/services work

## Next Steps After Refactoring

1. Update `AGENTS.md` documentation
2. Test on both Linux and Darwin systems
3. Monitor for issues over next few days
4. Consider updating README if needed

## Questions?

Refer to the detailed plan documents for:
- Research findings and context
- Detailed categorization of each file
- Complete command reference
- Testing strategies
- Rollback procedures

---

**Plan Status**: ✅ Complete - Ready for implementation  
**Created**: 2026-01-21  
**Research agents**: 5 parallel explore agents launched  
**Documents**: 3 comprehensive plans + this README
