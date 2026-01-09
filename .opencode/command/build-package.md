---
command: /build-package
description: Build a package locally for testing
syntax: |
  /build-package <name> [options]
options:
  - --verbose: Show detailed build output
  - --install: Install to user profile
  - --system <system>: Build for specific system
  - --dry-run: Check if buildable without building
examples:
  - "/build-package helium"
  - "/build-package neovim --verbose"
  - "/build-package my-package --install"
  - "/build-package my-package --system aarch64-linux"
---

# Build Package Command

Builds a package locally for testing before integrating into the flake.

## Usage

```bash
/build-package <name>             # Basic build
/build-package <name> --verbose   # Verbose output
/build-package <name> --install   # Install to profile
/build-package <name> --system x86_64-linux  # Cross-compile
/build-package <name> --dry-run   # Check without building
```

## Examples

### Build Package

```bash
$ /build-package helium

=== Building helium ===

Using: packages/helium.nix

1. Fetching source...
✅ Fetched from GitHub

2. Building...
Building with Cargo...
   Compiling helium v1.0.0
   Finished release [optimized] target(s)

3. Result:
/nix/store/xyz-helium-1.0.0

✅ Build successful
```

### Verbose Build

```bash
$ /build-package my-package --verbose

=== Building my-package (verbose) ===

Using: packages/my-package.nix

Source: /nix/store/abc-my-package-src
Hash: sha256-...

Build command:
> ./configure --prefix=/nix/store/xyz-my-package
> make
> make install

[Build output...]
```

### Install to Profile

```bash
$ /build-package helium --install

=== Building and installing helium ===

1. Building...
✅ Build successful

2. Installing to profile...
✅ Installed to: /nix/var/nix/profiles/per-user/zshen/profile

3. Running...
helium --version
1.0.0

✅ Installed and verified
```

### Cross-Platform

```bash
$ /build-package my-package --system aarch64-linux

=== Building for aarch64-linux ===

Using: packages/my-package.nix
System: aarch64-linux

Building...
✅ Build successful for aarch64-linux

Result: /nix/store/xyz-my-package-aarch64-linux
```

### Dry Run

```bash
$ /build-package new-package --dry-run

=== Checking new-package ===

1. Package definition exists?
✅ packages/new-package.nix found

2. Syntax check...
✅ Syntax OK

3. Fetch check...
   URL: https://github.com/user/new-package
   SHA256: abc123...
   → Would fetch successfully

4. Dependencies check...
   Build deps: [cargo, rustc]
   Runtime deps: []
   → All available

Ready to build. Run without --dry-run.
```

## Available Packages

| Package | Location | Status |
|---------|----------|--------|
| `neovim` | nvf module | ✅ Available |
| `helium` | packages/helium.nix | ✅ Available |
| `hello` | nixpkgs | ✅ Available |

## Creating New Package

```bash
# Create scaffold
/build-package --create my-package --type rust

# Edit the package
# packages/my-package.nix

# Test build
/build-package my-package

# Add to flake
# (handled by /flake-analyze)
```

## Troubleshooting

### Build Fails

```bash
# Check error
/build-package my-package 2>&1 | tail -50

Common issues:
- Wrong SHA256 → Update hash
- Missing dependency → Add to buildInputs
- Build system issue → Check buildPhase
```

### Package Not Found

```bash
# Check package exists
ls packages/

# Check flake output
nix eval .#packages --apply builtins.attrNames | grep package
```
