---
name: nix-package-updater
description: Update custom Nix packages in this repository (Helium, DevToys, agent-browser, opencode-morph-fast-apply). Use when a new version of these packages is released or when dependency hashes need updating. Triggers on "update helium", "bump devtoys version", "fix agent-browser hash", or "update custom packages".
---

# Nix Package Updater

This skill provides comprehensive procedures and guidelines for maintaining and updating custom Nix packages in this repository. These packages are defined in the `packages/` directory and are exposed via the `flake-parts/packages.nix` file.

## 1. Overview

Custom packages in this repository are managed using Nix flakes and the `flake-parts` framework. Unlike packages from the official `nixpkgs` repository, these are maintained locally to ensure specific versions, configurations, or wrappers are available.

Updating these packages involves a systematic process of:
1.  Identifying new upstream releases.
2.  Updating the version and source references in the Nix expressions.
3.  Recalculating cryptographic hashes for sources and dependencies.
4.  Verifying the build and installation phases.

The four primary custom packages handled by this skill are:
- **Helium** (`packages/helium.nix`): A lightweight web browser distributed as an AppImage.
- **DevToys** (`packages/devtoys.nix`): A Swiss Army knife for developers, extracted from a Debian package.
- **opencode-morph-fast-apply** (`packages/opencode-morph-fast-apply.nix`): An OpenCode plugin built using `buildNpmPackage`.
- **agent-browser** (`packages/agent-browser.nix`): A complex tool combining a pnpm-based Node.js app and a Rust CLI.

## 2. Quick Start

If you are already familiar with Nix, follow these accelerated steps:

1.  **Find Version**: Check the GitHub releases page for the target package.
2.  **Edit Nix File**: Open the corresponding file in `packages/`.
3.  **Bump Version**: Update the `version` variable and any architecture-specific URLs.
4.  **Reset Hashes**: Change all `sha256`, `hash`, or `cargoHash` values to `lib.fakeHash`.
5.  **Build**: Run `nix build .#<package-name>`.
6.  **Fix Hashes**: Copy the "got:" hash from the error output and paste it back into the file.
7.  **Repeat**: If the package has multiple hashes (like `agent-browser`), repeat the build/fix cycle for each one.
8.  **Verify**: Ensure the binary in `./result/bin/` works as expected.

## 3. Update by Package Type

### AppImage (helium.nix)

Helium is wrapped using `pkgs.appimageTools.wrapType2`. It uses a multi-architecture mapping to support both x86_64 and aarch64.

**File**: `packages/helium.nix`

**Update Procedure**:
1.  Visit [helium-linux releases](https://github.com/imputnet/helium-linux/releases).
2.  Note the new version number (e.g., `0.8.5.1`).
3.  Update the `version = "..."` line at the top of the `let` block.
4.  Replace the `sha256` values in the `srcs` attribute set with `lib.fakeHash`.
5.  Run `nix build .#helium`. Nix will provide the hash for your current architecture.
6.  Update the hash for your system. For the other architecture, you can either use a remote builder or wait for CI to provide the correct hash.

```nix
# Structure of helium.nix for reference
srcs = {
  x86_64-linux = {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    sha256 = "sha256-y4KzR+pkBUuyVU+ALrzdY0n2rnTB7lTN2ZmVSzag5vE="; # Update this
  };
  aarch64-linux = {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64.AppImage";
    sha256 = "sha256-fTPLZmHAqJqDDxeGgfSji/AY8nCt+dVeCUQIqB80f7M="; # Update this
  };
};
```

### Debian Package (devtoys.nix)

DevToys is updated by extracting a `.deb` file using `dpkg-deb`.

**File**: `packages/devtoys.nix`

**Update Procedure**:
1.  Check [DevToys releases](https://github.com/DevToys-app/DevToys/releases).
2.  Update the `version` variable.
3.  Update the `sha256` hashes in the `srcs` block.
4.  If the upstream naming convention for the `.deb` file changes, update the `url` template accordingly.
5.  Run `nix build .#devtoys`.

**Verification**: Since DevToys relies on `makeWrapper` to set the execution environment, verify the wrapper:
```bash
cat result/bin/devtoys # Should show the shell script invoking the real binary
```

### npm Package (opencode-morph-fast-apply.nix)

This package uses the `buildNpmPackage` helper. It is often pinned to a specific commit because it is a fast-moving plugin.

**File**: `packages/opencode-morph-fast-apply.nix`

**Update Procedure**:
1.  Identify the new commit hash on [GitHub](https://github.com/JRedeker/opencode-morph-fast-apply).
2.  Update `version` (use the date or the version from `package.json`).
3.  Update `src.rev` with the new commit hash.
4.  Update `src.sha256` using `lib.fakeHash`.
5.  Update `npmDepsHash` using `lib.fakeHash`. This hash represents the `node_modules` state and must be updated whenever `package-lock.json` changes.

```nix
pkgs.buildNpmPackage {
  pname = "opencode-morph-fast-apply";
  version = "1.5.1"; # Update

  src = pkgs.fetchFromGitHub {
    owner = "JRedeker";
    repo = "opencode-morph-fast-apply";
    rev = "new-rev-here"; # Update
    sha256 = lib.fakeHash; # Update
  };

  npmDepsHash = lib.fakeHash; # Update
}
```

### pnpm + Rust (agent-browser.nix)

This is the most complex package in the repository. It contains two distinct build processes: a Rust CLI and a pnpm-managed Node.js application.

**File**: `packages/agent-browser.nix`

**Update Procedure**:
1.  Check [agent-browser releases](https://github.com/vercel-labs/agent-browser).
2.  **Update Rust CLI**:
    - Update `rustCli.version`.
    - Update `rustCli.src.tag` or `rustCli.src.hash`.
    - Update `rustCli.cargoHash`. This is critical for Rust dependency reproducibility.
3.  **Update Main Package**:
    - Update the top-level `version` variable.
    - Update the `src.tag` or `src.hash` in the main `mkDerivation`.
    - Update `pnpmDeps.hash`. This requires `fetcherVersion = 2;` for compatibility with pnpm 9.
4.  Run `nix build .#agent-browser` and resolve hashes one by one.

**Important**: The Rust CLI is built separately and then copied into the final derivation. Ensure both parts are updated to matching versions to avoid compatibility issues.

## 4. Version Check Commands

You can use these snippets to check for updates without opening a browser:

```bash
# Get latest Helium version
curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest | jq -r .tag_name

# Get latest DevToys version
curl -s https://api.github.com/repos/DevToys-app/DevToys/releases/latest | jq -r .tag_name

# Get latest agent-browser version
curl -s https://api.github.com/repos/vercel-labs/agent-browser/releases/latest | jq -r .tag_name
```

## 5. Hash Update Workflow

The "Fake Hash Pattern" is the recommended way to update hashes in this repository.

1.  **Insert lib.fakeHash**: Replace the old `sha256` or `hash` with `lib.fakeHash`. This is a constant that evaluates to an empty hash string, which Nix recognizes as a placeholder.
2.  **Run Build**: Execute `nix build .#<package>`.
3.  **Catch Mismatch**: The build will fail with a "hash mismatch" error.
4.  **Extract Correct Hash**: Look for the `got:` line in the error message. It will look like `sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=`.
5.  **Update File**: Replace `lib.fakeHash` with the captured string.

**Note**: In some cases, Nix might report the hash in SRI format (starting with `sha256-`) even if the original used a different format. Always prefer the SRI format.

## 6. Build & Verify

After applying updates, you MUST verify the build:

```bash
# Build the package locally
nix build .#helium

# Check the binary is in the correct path
ls -l result/bin/helium

# Run a simple version check if supported
./result/bin/helium --version
```

If you are updating a Linux-only package (like `helium` or `devtoys`) from a Darwin system, you will not be able to build it locally unless you have a Linux remote builder. In such cases:
1.  Update the version and URLs.
2.  Set hashes to `lib.fakeHash`.
3.  Commit and rely on the CI results or a remote build machine.

## 7. Troubleshooting

### Mismatched Architectures
If you update `helium.nix` or `devtoys.nix` and get a hash mismatch immediately but the hash looks "correct", check if you accidentally swapped the `x86_64` and `aarch64` hashes.

### npmDepsHash Failures
If `buildNpmPackage` fails with a hash mismatch on `npmDepsHash`, it means the `package-lock.json` has changed. This is expected during a version bump. If it fails *without* a version bump, the upstream might have force-pushed or changed a dependency in place (rare but possible).

### CargoHash Mismatch
In `agent-browser.nix`, the `cargoHash` must be updated if any dependency in `Cargo.toml` or `Cargo.lock` changes. If the Rust build fails with "checksum mismatch for vendor source", your `cargoHash` is outdated.

### Missing Runtime Libraries
If the application builds but fails at runtime with "libX11.so.6 not found" (common for AppImages), you need to add the missing library to `extraPkgs` in `helium.nix` or `buildInputs` in `devtoys.nix`.

## 8. When NOT to Use

- **Generic Nixpkgs Updates**: Do not use this skill to update standard packages like `bash`, `git`, or `ripgrep`. These are managed by updating the `nixpkgs` input in `flake.nix`.
- **NixOS/Home Manager Config**: This skill is for *package derivations*, not for system configuration settings.
- **Initial Packaging**: If a software is not yet in `packages/`, use the `nix-package-creator` skill instead to create the initial derivation.
- **Neovim Configuration**: The `neovim` package in this repo is a complex wrapper around `nvf` and should be updated by modifying the `nvf` modules in `modules/home-manager/features/neovim/nvf`.
