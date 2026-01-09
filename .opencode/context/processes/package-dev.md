# Package Development Workflow

Workflow for creating and testing custom Nix packages.

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                 Package Development Workflow                 │
├─────────────────────────────────────────────────────────────┤
│  1. Plan Package                                             │
│     → Define package requirements and dependencies           │
│  2. Create Package Definition                                │
│     → Write package.nix file                                 │
│  3. Test Build                                               │
│     → Build package locally                                  │
│  4. Test Functionality                                       │
│     → Run package and verify it works                        │
│  5. Cross-Platform Test                                      │
│     → Test on multiple architectures                         │
│  6. Integrate with Flake                                     │
│     → Add to flake.nix outputs                               │
│  7. Document and Commit                                      │
│     → Document changes, commit to git                        │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Plan Package

### Determine Package Type

| Type | Build System | Example |
|------|--------------|---------|
| **Rust** | Cargo | `buildRustPackage` |
| **Go** | Go modules | `buildGoModule` |
| **Python** | pip/setup.py | `buildPythonApplication` |
| **CMake** | CMake | `cmake.buildCMakePackage` |
| **Generic** | Make/autotools | `stdenv.mkDerivation` |
| **Vim Plugin** | Vim plugin manager | `vimUtils.buildVimPlugin` |

### Define Requirements

```markdown
# Package: my-package

## Purpose
Brief description of what the package does

## Source
- Repository: https://github.com/user/my-package
- License: MIT
- Version: 1.0.0

## Dependencies
- Build: [list]
- Runtime: [list]

## Platforms
- [x] x86_64-linux
- [x] aarch64-linux
- [ ] aarch64-darwin (if supported)

## Integration
- Where to place: `packages/my-package.nix`
- Flake output: `packages.my-package`
```

## Step 2: Create Package Definition

### Rust Package

```nix
# packages/my-package.nix
{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "my-package";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "user";
    repo = "my-package";
    rev = "v${version}";
    sha256 = "0000000000000000000000000000000000000000";
  };
  
  cargoLock = {
    lockFile = ./Cargo.lock;
  };
  
  meta = with lib; {
    description = "My package description";
    homepage = "https://github.com/user/my-package";
    license = licenses.mit;
    maintainers = with maintainers; ["zshen"];
    platforms = platforms.linux;
  };
}
```

### Go Package

```nix
# packages/my-go-tool.nix
{ lib, buildGoModule }:

buildGoModule {
  pname = "my-go-tool";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "user";
    repo = "my-go-tool";
    rev = "v${version}";
    sha256 = "0000000000000000000000000000000000000000";
  };
  
  vendorHash = "0000000000000000000000000000000000000000";
  
  meta = with lib; {
    description = "My Go tool description";
    homepage = "https://github.com/user/my-go-tool";
    license = licenses.mit;
    maintainers = with maintainers; ["zshen"];
  };
}
```

### Vim Plugin

```nix
# In neovim module
vimPlugins.my-plugin = vimUtils.buildVimPlugin {
  name = "my-plugin";
  src = inputs.my-plugin;
  meta = {
    description = "My Neovim plugin";
    homepage = "https://github.com/user/my-plugin.nvim";
  };
};
```

### Generic Package

```nix
# packages/my-tool.nix
{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "my-tool";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "user";
    repo = "my-tool";
    rev = "v${version}";
    sha256 = "0000000000000000000000000000000000000000";
  };
  
  nativeBuildInputs = [ autoreconfHook automake pkg-config ];
  buildInputs = [ libfoo ];
  
  buildPhase = ''
    ./configure --prefix=$out
    make
  '';
  
  installPhase = ''
    mkdir -p $out/bin
    cp my-tool $out/bin/
  '';
  
  meta = with lib; {
    description = "My tool description";
    homepage = "https://github.com/user/my-tool";
    license = licenses.mit;
    maintainers = with maintainers; ["zshen"];
    platforms = platforms.linux;
  };
}
```

## Step 3: Test Build

### Basic Build

```bash
# Build package
nix build .#my-package

# Build with verbose output
nix build .#my-package --verbose

# Build and show logs
nix build .#my-package --log-format raw 2>&1 | tail -100
```

### Get SHA256

```bash
# Fetch source and get hash
nix-prefetch-url https://github.com/user/my-package/archive/v1.0.0.tar.gz

# Or use fetchFromGitHub directly
nix build -f - <<'EOF'
{ lib, fetchFromGitHub }:
fetchFromGitHub {
  owner = "user";
  repo = "my-package";
  rev = "v1.0.0";
  sha256 = lib.fakeHash;
}
EOF
```

### Test Dependencies

```bash
# Check build dependencies
nix-shell -p my-package --run "my-package --help"

# Develop in shell
nix develop -c my-package --help
```

## Step 4: Test Functionality

### Run Package

```bash
# Run directly from build
./result/bin/my-package --version

# Or via nix run
nix run .#my-package -- --version

# Install to profile
nix profile install .#my-package

# Run from profile
my-package --version
```

### Verify Behavior

```bash
# Test all features
my-package feature1 --check
my-package feature2 --check

# Test error handling
my-package invalid-input 2>&1 | grep -q "error" && echo "OK"
```

## Step 5: Cross-Platform Test

### Test on Multiple Systems

```bash
# x86_64-linux (native)
nix build .#my-package

# aarch64-linux (emulated)
nix build .#my-package --system aarch64-linux

# aarch64-darwin (if supported)
nix build .#my-package --system aarch64-darwin
```

### Platform Filtering

```nix
# In package.nix
meta = with lib; {
  # Only Linux
  platforms = platforms.linux;
  
  # Only Darwin
  platforms = platforms.darwin;
  
  # Multiple
  platforms = platforms.linux ++ platforms.darwin;
};
```

## Step 6: Integrate with Flake

### Add to flake.nix

```nix
# In outputs.packages
packages = forAllSystems (pkgs: let
  inherit (pkgs.lib) optionalAttrs;
in {
  my-package = import ./packages/my-package.nix { inherit pkgs; };
} // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  # Platform-specific packages
  linux-only-tool = import ./packages/linux-only.nix { inherit pkgs; };
});
```

### With flake-parts (target)

```nix
# In perSystem
perSystem = { pkgs, ... }: {
  packages = {
    my-package = import ./packages/my-package.nix { inherit pkgs; };
  };
};
```

### Add to Templates (if applicable)

```nix
# If creating a template
templates = {
  my-template = {
    path = ./templates/my-template;
    description = "Template with my-package";
  };
};
```

## Step 7: Document and Commit

### Update README

```markdown
## Packages

This flake provides the following packages:

| Package | Description | Platforms |
|---------|-------------|-----------|
| `my-package` | My package description | Linux |
| `neovim` | Neovim with custom config | All |
```

### Commit

```bash
git add packages/my-package.nix
git commit -m "packages: add my-package

- Add my-package version 1.0.0
- Rust-based CLI tool
- Supports x86_64-linux and aarch64-linux

See packages/my-package.nix for details."
```

## Update Existing Package

```bash
# Update version in package.nix
# Fetch new hash
nix-prefetch-url https://github.com/user/my-package/archive/v2.0.0.tar.gz

# Update sha256 in package.nix
# Build and test
nix build .#my-package

# Commit
git add packages/my-package.nix
git commit -m "packages: my-package 2.0.0

- Update to version 2.0.0
- New features: [list]
- Breaking changes: [list]"
```

## Troubleshooting

### Build Fails

```bash
# Check build log
nix build .#my-package 2>&1 | tail -100

# Common issues:
# - Wrong sha256
# - Missing dependency
# - Build system not found
```

### Wrong Hash

```bash
# Get correct hash
nix-prefetch-url https://github.com/user/my-package/archive/v1.0.0.tar.gz

# Update package.nix with correct hash
```

### Platform Not Supported

```bash
# Check platform support
nix-instantiate --eval -E '
  let
    pkg = (import ./packages/my-package.nix {
      pkgs = import <nixpkgs> { system = "x86_64-linux"; };
    });
  in
    pkg.meta.platforms or ["all"]
'

# Add platform support if needed
# Edit meta.platforms in package.nix
```

## Best Practices

1. **Fetch with immutable refs** - Use commits/tags, not branches
2. **Always verify checksums** - Fetch and verify sha256
3. **Test on multiple platforms** - Linux and Darwin if applicable
4. **Complete meta information** - Description, license, maintainers
5. **Use appropriate builder** - buildRustPackage, buildGoModule, etc.
6. **Document changes** - Clear commit messages
7. **Keep packages small** - Single purpose per package
8. **Version pinning** - Use specific versions, not latest
