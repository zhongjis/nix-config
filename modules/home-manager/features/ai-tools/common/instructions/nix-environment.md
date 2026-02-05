# Nix Environment Awareness

**Context:** This system may use NixOS, nix-darwin (macOS), or have Nix installed as a standalone package manager. Traditional package installation methods may not work or may not persist correctly.

## When a Command is Not Found

**MANDATORY PROTOCOL:**

1. **Confirm the OS/Environment FIRST**
   ```bash
   uname -a
   cat /etc/os-release 2>/dev/null || sw_vers 2>/dev/null
   ```

2. **Check if Nix is Available**
   ```bash
   command -v nix && echo "Nix is installed"
   ```

3. **If Nix is Present: Use `nix shell` for Ad-hoc Commands**
   ```bash
   # WRONG: Try to install globally (may fail or not persist)
   apt install jq      # Won't work on NixOS
   brew install jq     # May conflict with Nix on macOS
   
   # CORRECT: Use nix shell for ad-hoc execution
   nix shell nixpkgs#jq -c "jq '.key' file.json"
   
   # Or for multiple packages
   nix shell nixpkgs#jq nixpkgs#yq -c "jq ... | yq ..."
   ```

## Nix Package Manager Considerations

### Systems Where Nix May Be Present

| System | Configuration |
|--------|---------------|
| **NixOS** | Full OS managed by Nix - no traditional package managers |
| **macOS + nix-darwin** | System packages managed by Nix, Homebrew may coexist |
| **macOS + Nix** | Nix installed standalone alongside Homebrew |
| **Linux + Nix** | Nix installed alongside system package manager |

### What to Avoid on Nix-Managed Systems

| Action | Issue |
|--------|-------|
| `apt/yum install` on NixOS | NixOS doesn't use traditional package managers |
| `pip install --global` | Global Python packages break Nix isolation |
| `npm install -g` | Global npm packages may not persist or integrate |
| `sudo make install` | Won't integrate with Nix package management |

### What You SHOULD Do

| Need | Solution |
|------|----------|
| Run a command once | `nix shell nixpkgs#package -c command args` |
| Run in current shell | `nix shell nixpkgs#package` then run commands |
| Multiple packages | `nix shell nixpkgs#pkg1 nixpkgs#pkg2 -c ...` |
| Development environment | Check for `flake.nix` and use `nix develop` |

## Quick Reference

### Ad-hoc Command Execution
```bash
# Pattern: nix shell nixpkgs#<package> -c <command> [args]

# Examples
nix shell nixpkgs#jq -c "jq '.name' package.json"
nix shell nixpkgs#ripgrep -c "rg 'pattern' ."
nix shell nixpkgs#fd -c "fd -e nix"
nix shell nixpkgs#httpie -c "http GET example.com"
nix shell nixpkgs#curl nixpkgs#jq -c "curl -s api.example.com | jq ."
```

### Finding Package Names
```bash
# Search for packages
nix search nixpkgs packagename

# Or use the nh wrapper if available
nh search packagename
```

### Check Environment Type
```bash
# NixOS
nixos-version 2>/dev/null && echo "NixOS"

# nix-darwin (macOS with Nix system management)
command -v darwin-rebuild && echo "nix-darwin"

# Standalone Nix
command -v nix && echo "Nix available"

# Check for Nix store
ls /nix/store &>/dev/null && echo "Nix store present"
```

## Decision Tree

```
Command not found?
    │
    ├─► Is `nix` command available?
    │       │
    │       ├─► YES: Use `nix shell nixpkgs#package -c command`
    │       │
    │       └─► NO: Use appropriate package manager for that OS
    │               (apt, brew, yum, etc.)
    │
    └─► When in doubt, check: command -v nix
```

## Important Notes

1. **Ephemeral by Design**: `nix shell` packages don't persist after the shell exits - this is intentional
2. **Reproducibility**: Nix ensures consistent package versions across runs
3. **No Side Effects**: Running `nix shell` won't modify system configuration
4. **Flakes Preferred**: If the project has `flake.nix`, prefer `nix develop` for development shells
5. **Check Project First**: Always check if the project provides dev shells before reaching for `nix shell`
6. **Mixed Systems**: On macOS with both Nix and Homebrew, prefer `nix shell` for consistency with this configuration
