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

## Ad-hoc Python with Libraries

Python is the most common case where agents need packages beyond the base interpreter. The standard `pip install` approach conflicts with Nix isolation.

### Option 1: `uv` (Preferred when available)

`uv` handles ephemeral Python environments automatically:

```bash
# Check if uv is available
command -v uv && echo "uv is installed"

# Run script with ad-hoc dependencies
uv run --with pandas --with requests python3 script.py

# One-liner execution
uv run --with requests python3 -c "import requests; print(requests.get('https://example.com').status_code)"

# Multiple packages
uv run --with pandas --with matplotlib --with numpy python3 analyze.py
```

For self-contained scripts, use PEP 723 inline metadata:

```python
#!/usr/bin/env -S uv run
# /// script
# dependencies = ["pandas", "requests"]
# ///
import pandas as pd
import requests
# ... script body
```

### Option 2: `nix shell` with `python3.withPackages`

Pure Nix approach — works anywhere Nix is installed:

```bash
# Python with specific packages
nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages (ps: with ps; [pandas requests])' -c python3 script.py

# Interactive Python with packages
nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages (ps: with ps; [numpy matplotlib])'
```

> **Note:** Nixpkgs Python package names may differ from PyPI names. Use `nix search nixpkgs python3Packages.<name>` to find the correct attribute.

### What to Avoid with Python

| Action | Issue |
|--------|-------|
| `pip install <package>` | Breaks Nix isolation, may not persist |
| `pip install --user <package>` | Pollutes user site-packages, conflicts with Nix |
| `python -m venv && pip install` | Manual venvs bypass Nix dependency tracking |
| `sudo pip install` | System-wide install, breaks Nix-managed Python |

### Decision Tree for Python

```
Need Python with libraries?
    │
    ├─► Is `uv` available? (`command -v uv`)
    │       │
    │       ├─► YES: uv run --with <pkg1> --with <pkg2> python3 script.py
    │       │
    │       └─► NO: Is `nix` available?
    │               │
    │               ├─► YES: nix shell --impure --expr 'with import <nixpkgs> {};
    │               │        python3.withPackages (ps: with ps; [pkg1 pkg2])' -c python3 script.py
    │               │
    │               └─► NO: python -m venv .venv && source .venv/bin/activate && pip install ...
    │
    └─► For project work: Check for flake.nix/pyproject.toml first → use `nix develop` or `uv sync`
```

## Ad-hoc Node.js / npm Packages

Running Node.js tools and scripts with npm dependencies without polluting the global environment.

### Option 1: `npx` (Preferred when Node.js is available)

`npx` runs packages without global install:

```bash
# Run a CLI tool once
npx cowsay "hello"
npx ts-node script.ts
npx tsx script.ts

# Run with a specific package version
npx create-react-app@latest my-app
npx prettier --write .
```

### Option 2: `nix shell` + `npx`

When Node.js itself is not installed:

```bash
# Get Node.js via Nix, then use npx
nix shell nixpkgs#nodejs -c npx cowsay "hello"
nix shell nixpkgs#nodejs -c npx ts-node script.ts

# Get Node.js + specific global tools
nix shell nixpkgs#nodejs nixpkgs#nodePackages.typescript -c tsc --version
nix shell nixpkgs#nodejs nixpkgs#nodePackages.prettier -c prettier --write .

# Interactive shell with Node.js
nix shell nixpkgs#nodejs
```

### Running Scripts with Dependencies

For scripts that need npm packages:

```bash
# If package.json exists in the project
nix shell nixpkgs#nodejs -c sh -c "npm install && node script.js"

# For a quick one-off with a dependency
nix shell nixpkgs#nodejs -c npx -p axios -p cheerio node -e "const axios = require('axios'); ..."
```

### What to Avoid with Node.js

| Action | Issue |
|--------|-------|
| `npm install -g <package>` | Global installs may not persist, conflicts with Nix |
| `sudo npm install -g` | System-wide install, breaks Nix-managed Node.js |
| `corepack enable` without Nix | May conflict with Nix-managed package managers |

### Decision Tree for Node.js

```
Need to run a Node.js tool or script?
    │
    ├─► Is `node`/`npx` available? (`command -v npx`)
    │       │
    │       ├─► YES: npx <tool> or npm install (local to project)
    │       │
    │       └─► NO: Is `nix` available?
    │               │
    │               ├─► YES: nix shell nixpkgs#nodejs -c npx <tool>
    │               │
    │               └─► NO: Install Node.js via system package manager
    │
    └─► For project work: Check for flake.nix first → use `nix develop`
```

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
