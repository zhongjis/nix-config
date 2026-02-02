---
name: nix-package-creator
description: Create Nix package derivations for this flake-parts repository. Use when packaging new software, wrapping AppImages, extracting .deb files, building from source, or creating language-specific packages (Python, Go, Rust, Node.js/npm/pnpm/yarn). Triggers on requests like "package X", "add Y to packages/", "create derivation for Z", "wrap this AppImage/binary", or "package this npm/node project".
---

# Nix Package Creator

Create Nix packages for this flake-parts-based repository. Packages go in `packages/` and are exposed via `flake-parts/packages.nix`.

## Quick Start

1. Identify package type (see decision tree below)
2. Create `packages/<name>.nix` using appropriate template
3. Register in `flake-parts/packages.nix`
4. Build with `nix build .#<name>`

## Package Type Decision Tree

```
What do you have?
├─ AppImage (.AppImage file)
│   └─ Use: appimageTools.wrapType2 (see AppImage section)
├─ .deb package
│   └─ Use: stdenv.mkDerivation + dpkg (see Deb section)
├─ Prebuilt binary/tarball
│   └─ Use: stdenv.mkDerivation with autoPatchelfHook
├─ Source code
│   ├─ Python → buildPythonPackage or buildPythonApplication
│   ├─ Go → buildGoModule
│   ├─ Rust → rustPlatform.buildRustPackage
│   ├─ Node.js/JavaScript
│   │   ├─ package-lock.json → buildNpmPackage
│   │   ├─ yarn.lock → yarn2nix / mkYarnPackage
│   │   ├─ pnpm-lock.yaml → pnpm.fetchDeps + custom build
│   │   └─ Electron app → buildNpmPackage + ELECTRON_SKIP_BINARY_DOWNLOAD
│   └─ C/C++/other → stdenv.mkDerivation
└─ Override existing nixpkgs package
    └─ Use overlay in overlays/default.nix
```

## Package File Structure

All packages follow this pattern:

```nix
{
  pkgs,
  lib,
}:
let
  pname = "package-name";
  version = "1.0.0";
  # ... sources, helpers ...
in
pkgs.<builder> {
  inherit pname version;
  # ... builder-specific attributes ...
  meta = {
    description = "Short description";
    homepage = "https://example.com";
    license = lib.licenses.mit;  # or appropriate license
    platforms = lib.platforms.linux;  # or darwin, unix, all
    mainProgram = "binary-name";
  };
}
```

## AppImage Packages

For distributing Linux desktop apps packaged as AppImages:

```nix
{
  pkgs,
  lib,
}:
let
  pname = "app-name";
  version = "1.0.0";

  # Multi-arch support
  srcs = {
    x86_64-linux = {
      url = "https://example.com/app-${version}-x86_64.AppImage";
      sha256 = lib.fakeHash;  # Replace after first build attempt
    };
    aarch64-linux = {
      url = "https://example.com/app-${version}-aarch64.AppImage";
      sha256 = lib.fakeHash;
    };
  };

  srcInfo = srcs.${pkgs.system} or (throw "Unsupported system: ${pkgs.system}");
  src = pkgs.fetchurl { inherit (srcInfo) url sha256; };
  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [ ];  # Add runtime dependencies here

  extraInstallCommands = ''
    # Install desktop file
    install -Dm644 ${appimageContents}/app-name.desktop \
      $out/share/applications/${pname}.desktop

    # Fix desktop file paths
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail "Exec=AppRun" "Exec=${pname}"

    # Install icons
    cp -r ${appimageContents}/usr/share/icons $out/share/icons
  '';

  meta = {
    description = "App description";
    homepage = "https://example.com";
    license = lib.licenses.unfree;  # or appropriate
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
```

## Deb Packages

For extracting and wrapping Debian packages:

```nix
{
  pkgs,
  lib,
}:
let
  pname = "app-name";
  version = "1.0.0";

  srcs = {
    x86_64-linux = {
      url = "https://example.com/app_${version}_amd64.deb";
      sha256 = lib.fakeHash;
    };
    aarch64-linux = {
      url = "https://example.com/app_${version}_arm64.deb";
      sha256 = lib.fakeHash;
    };
  };

  srcInfo = srcs.${pkgs.system} or (throw "Unsupported system: ${pkgs.system}");
in
pkgs.stdenv.mkDerivation {
  inherit pname version;
  src = pkgs.fetchurl { inherit (srcInfo) url sha256; };

  nativeBuildInputs = [
    pkgs.dpkg
    pkgs.makeWrapper
    pkgs.autoPatchelfHook  # Auto-fix library paths
  ];

  buildInputs = [
    # Add runtime library dependencies here
    pkgs.stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackCmd = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share

    # Copy application files (adjust paths as needed)
    cp -r usr/share/* $out/share/ || true
    cp -r opt/${pname} $out/opt/${pname} || true

    # Create wrapper with library paths
    makeWrapper $out/opt/${pname}/${pname} $out/bin/${pname} \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}"

    runHook postInstall
  '';

  meta = {
    description = "App description";
    homepage = "https://example.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
```

## Source Builds (stdenv.mkDerivation)

For building from source with standard configure/make:

```nix
{
  pkgs,
  lib,
}:
let
  pname = "app-name";
  version = "1.0.0";
in
pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v${version}";  # or commit hash
    sha256 = lib.fakeHash;
  };

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.cmake  # or meson, autoconf, etc.
  ];

  buildInputs = [
    # Runtime dependencies
  ];

  # For non-standard builds:
  # configurePhase = ''...'';
  # buildPhase = ''...'';
  # installPhase = ''...'';

  meta = {
    description = "App description";
    homepage = "https://github.com/owner/repo";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = pname;
  };
}
```

## Node.js / JavaScript Packages

### buildNpmPackage (Recommended for npm projects)

For projects with `package-lock.json`:

```nix
{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "app-name";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v1.0.0";
    sha256 = lib.fakeHash;
  };

  npmDepsHash = lib.fakeHash;  # Run build, copy correct hash

  # For native modules:
  # makeCacheWritable = true;

  # Override node version if needed:
  # nodejs = pkgs.nodejs_20;

  # For packages that output a CLI:
  # postInstall = ''
  #   mkdir -p $out/bin
  #   ln -s $out/lib/node_modules/app-name/bin/cli.js $out/bin/app-name
  # '';

  meta = {
    description = "Node app";
    homepage = "https://github.com/owner/repo";
    license = lib.licenses.mit;
    mainProgram = "app-name";
  };
}
```

### Electron Applications

For Electron apps, prevent binary downloads in sandbox:

```nix
{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "electron-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v1.0.0";
    sha256 = lib.fakeHash;
  };

  npmDepsHash = lib.fakeHash;

  # CRITICAL: Prevent electron from downloading binaries
  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  # Use system electron
  nativeBuildInputs = [ pkgs.makeWrapper ];

  postInstall = ''
    makeWrapper ${pkgs.electron}/bin/electron $out/bin/electron-app \
      --add-flags $out/lib/node_modules/electron-app/dist/main.js
  '';

  meta = {
    description = "Electron app";
    license = lib.licenses.mit;
    mainProgram = "electron-app";
  };
}
```

### mkYarnPackage (For yarn projects)

For projects with `yarn.lock`:

```nix
{
  pkgs,
  lib,
}:
pkgs.mkYarnPackage {
  pname = "yarn-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v1.0.0";
    sha256 = lib.fakeHash;
  };

  packageJSON = ./package.json;  # or "${src}/package.json"
  yarnLock = ./yarn.lock;        # or "${src}/yarn.lock"

  # Generate with: nix-shell -p yarn yarn2nix --run "yarn2nix > yarn.nix"
  # yarnNix = ./yarn.nix;  # Optional, for reproducibility

  meta = {
    description = "Yarn app";
    license = lib.licenses.mit;
    mainProgram = "yarn-app";
  };
}
```

### pnpm Projects (Complex Pattern)

For pnpm projects, use a multi-stage approach (see `packages/agent-browser.nix` for full example):

```nix
{
  pkgs,
  lib,
}:
let
  pname = "pnpm-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v${version}";
    sha256 = lib.fakeHash;
  };

  # Fetch pnpm dependencies
  pnpmDeps = pkgs.pnpm.fetchDeps {
    inherit pname version src;
    hash = lib.fakeHash;
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    pkgs.nodejs
    pkgs.pnpm.configHook
    pkgs.makeWrapper
  ];

  inherit pnpmDeps;

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/${pname}
    cp -r dist node_modules package.json $out/lib/${pname}/

    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/${pname} \
      --add-flags "$out/lib/${pname}/dist/index.js"
    runHook postInstall
  '';

  meta = {
    description = "pnpm app";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
```

### Node.js with Native Dependencies

For packages with native bindings that need compilation:

```nix
{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "native-node-app";
  version = "1.0.0";

  src = ./.; # or fetchFromGitHub

  npmDepsHash = lib.fakeHash;

  # Enable writing to npm cache for native rebuilds
  makeCacheWritable = true;

  # Native build dependencies
  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.python3  # node-gyp needs python
  ];

  # Native runtime dependencies
  buildInputs = [
    pkgs.openssl
    pkgs.libsecret  # For keytar, etc.
  ];

  # For canvas, sharp, or other image libraries:
  # buildInputs = [ pkgs.cairo pkgs.pango pkgs.libjpeg ];

  meta = {
    description = "Node app with native deps";
    license = lib.licenses.mit;
  };
}
```

## Other Language-Specific Builders

### Python (buildPythonApplication)

```nix
{
  pkgs,
  lib,
}:
pkgs.python3Packages.buildPythonApplication {
  pname = "app-name";
  version = "1.0.0";
  pyproject = true;  # For pyproject.toml-based projects

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v1.0.0";
    sha256 = lib.fakeHash;
  };

  build-system = [ pkgs.python3Packages.setuptools ];

  dependencies = [
    pkgs.python3Packages.requests
    # ... other Python deps
  ];

  meta = {
    description = "Python app";
    license = lib.licenses.mit;
    mainProgram = "app-name";
  };
}
```

### Go (buildGoModule)

```nix
{
  pkgs,
  lib,
}:
pkgs.buildGoModule {
  pname = "app-name";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v1.0.0";
    sha256 = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;  # or null if vendor/ is committed

  ldflags = [ "-s" "-w" ];  # Strip debug info

  meta = {
    description = "Go app";
    license = lib.licenses.mit;
    mainProgram = "app-name";
  };
}
```

### Rust (buildRustPackage)

```nix
{
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "app-name";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v1.0.0";
    sha256 = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;  # or useFetchCargoVendor = true

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.openssl ];  # Common Rust deps

  meta = {
    description = "Rust app";
    license = lib.licenses.mit;
    mainProgram = "app-name";
  };
}
```

## Registering Packages

Add to `flake-parts/packages.nix`:

```nix
# In perSystem = { pkgs, lib, ... }:
packages = {
  # Cross-platform packages
  my-package = import ../packages/my-package.nix {
    inherit pkgs;
    lib = pkgs.lib;
  };
}
# Linux-only packages
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  linux-only-pkg = import ../packages/linux-only-pkg.nix {
    inherit pkgs;
    lib = pkgs.lib;
  };
}
# Darwin-only packages
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  darwin-only-pkg = import ../packages/darwin-only-pkg.nix {
    inherit pkgs;
    lib = pkgs.lib;
  };
};
```

## Getting Hashes

Use `lib.fakeHash` initially, then run:

```bash
nix build .#package-name
```

Nix will fail with the correct hash. Replace `lib.fakeHash` with the provided hash.

For `fetchFromGitHub`:

```bash
nix-prefetch-github owner repo --rev v1.0.0
```

For npm deps hash:

```bash
# Build will fail and provide correct hash
nix build .#package-name 2>&1 | grep "got:"
```

## Common Patterns

### makeWrapper for environment setup

```nix
nativeBuildInputs = [ pkgs.makeWrapper ];
postInstall = ''
  wrapProgram $out/bin/app \
    --prefix PATH : ${lib.makeBinPath [ pkgs.git pkgs.curl ]} \
    --set ENV_VAR "value"
'';
```

### autoPatchelfHook for binary dependencies

```nix
nativeBuildInputs = [ pkgs.autoPatchelfHook ];
buildInputs = [ pkgs.stdenv.cc.cc.lib ];  # Common libs
```

### substituteInPlace for file patching

```nix
postPatch = ''
  substituteInPlace src/config.py \
    --replace-fail "/usr/bin/git" "${pkgs.git}/bin/git"
'';
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Hash mismatch | Use `lib.fakeHash`, build, copy correct hash |
| Missing library | Add to `buildInputs`, use `autoPatchelfHook` |
| Can't find binary | Check `mainProgram`, verify install path |
| Desktop file broken | Fix paths with `substituteInPlace` |
| Platform error | Check `platforms` in meta, use `optionalAttrs` |
| npm ENOENT errors | Missing native deps, check `buildInputs` |
| Electron download fails | Set `ELECTRON_SKIP_BINARY_DOWNLOAD = "1"` |
| node-gyp errors | Add `python3` to `nativeBuildInputs` |
| pnpm cache errors | Use `pnpm.fetchDeps` + `pnpm.configHook` |
