---
name: nix-package-creator
description: Create Nix package derivations for this flake-parts repository. Use when packaging new software, wrapping AppImages, extracting .deb files, building from source, or creating language-specific packages (Python, Go, Rust, Node.js/npm/pnpm/yarn). Triggers on requests like "package X", "add Y to packages/", "create derivation for Z", "wrap this AppImage/binary", or "package this npm/node project".
---

# Nix Package Creator

Create Nix packages for this flake-parts-based repository. Packages go in `packages/` and are exposed via `flake-parts/packages.nix`.

## Quick Start

1. Identify package type (see decision tree)
2. Create `packages/<name>.nix` using appropriate template
3. Register in `flake-parts/packages.nix`
4. Track with `jj file track packages/<name>.nix` (flakes require VCS tracking)
5. Build with `nix build .#<name>` (use `lib.fakeHash` first, fix hashes iteratively)
6. Verify with `nix flake check`

## Package Type Decision Tree

```
What do you have?
├─ AppImage (.AppImage file)
│   └─ Use: appimageTools.wrapType2 (see AppImage section below)
├─ .deb package
│   └─ Use: stdenv.mkDerivation + dpkg — see references/deb.md
├─ Prebuilt binary/tarball
│   └─ Use: stdenv.mkDerivation with autoPatchelfHook — see references/source-builds.md
├─ Source code
│   ├─ Node.js/JavaScript → see references/nodejs.md
│   ├─ Python → see references/source-builds.md
│   ├─ Go → see references/source-builds.md
│   ├─ Rust → see references/source-builds.md
│   └─ C/C++/other → see references/source-builds.md
└─ Override existing nixpkgs package
    └─ Use overlay in overlays/default.nix
```

## Real Examples in This Repo

Before writing a derivation, **read existing packages** for battle-tested patterns:

| Package | Type | File | Notes |
|---------|------|------|-------|
| Helium | AppImage (multi-arch) | `packages/helium.nix` | `srcs` attrset keyed by `pkgs.system` |
| Quounter | AppImage (single-arch, Tauri) | `packages/quounter.nix` | Direct `fetchurl`, no AppRun fix needed |
| DevToys | Deb extraction | `packages/devtoys.nix` | `dpkg-deb` + `makeWrapper` + `autoPatchelfHook` |
| Agent Browser | pnpm complex build | `packages/agent-browser.nix` | `pnpm.fetchDeps` + `pnpm.configHook` |
| opencode-morph-fast-apply | npm build | `packages/opencode-morph-fast-apply.nix` | `buildNpmPackage` |

## AppImage Packages

### Pre-Packaging Inspection (CRITICAL)

**ALWAYS inspect AppImage contents** before finalizing the derivation:

1. Write initial derivation with `lib.fakeHash` → build → get correct hash → update
2. Build again — if file path errors, inspect the extracted store path:

```bash
ls /nix/store/*-<pname>-<version>-extracted/
find /nix/store/*-<pname>-<version>-extracted/ -name "*.desktop"
find /nix/store/*-<pname>-<version>-extracted/ -name "*.png" -o -name "*.svg"
cat /nix/store/*-<pname>-<version>-extracted/*.desktop
```

**Gotchas:**
- Desktop files are often **Capitalized** (`Quounter.desktop` not `quounter.desktop`)
- Tauri apps use `Exec=appname` (lowercase) — skip `substituteInPlace` for AppRun replacement
- Icons may exist at root AND in `usr/share/icons/` — prefer the `usr/share/icons/` tree

### Template

For multi-arch releases, use an `srcs` attrset keyed by `pkgs.system`. For single-arch, simplify to a direct `fetchurl`:

```nix
{
  pkgs,
  lib,
}:
let
  pname = "app-name";
  version = "1.0.0";

  # Multi-arch: use srcs attrset (see packages/helium.nix)
  # srcs = {
  #   x86_64-linux = { url = "..."; sha256 = lib.fakeHash; };
  #   aarch64-linux = { url = "..."; sha256 = lib.fakeHash; };
  # };
  # srcInfo = srcs.${pkgs.system} or (throw "Unsupported system: ${pkgs.system}");
  # src = pkgs.fetchurl { inherit (srcInfo) url sha256; };

  # Single-arch: direct fetchurl (see packages/quounter.nix)
  src = pkgs.fetchurl {
    url = "https://example.com/App_${version}_amd64.AppImage";
    sha256 = lib.fakeHash;
    name = "${pname}-${version}.AppImage";
  };

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [ ];

  extraInstallCommands = ''
    # Desktop file name is often Capitalized — inspect extracted contents first!
    install -Dm644 ${appimageContents}/AppName.desktop \
      $out/share/applications/${pname}.desktop

    # Only if desktop file has Exec=AppRun (NOT needed for Tauri apps):
    # substituteInPlace $out/share/applications/${pname}.desktop \
    #   --replace-fail "Exec=AppRun" "Exec=${pname}"

    cp -r ${appimageContents}/usr/share/icons $out/share/icons
  '';

  meta = {
    description = "Short description";
    homepage = "https://example.com";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
```

### Tauri Applications

- Desktop file: `AppName.desktop` (capitalized, matches Tauri app name)
- `Exec=` is already set to lowercase binary name — no AppRun fix needed
- Icons in `usr/share/icons/hicolor/` with all standard sizes
- Use AppImage path — do NOT try to build from source (Tauri toolchain is complex in Nix sandbox)
- `.deb` also available but AppImage is simpler to package

## Registering Packages

Add to `flake-parts/packages.nix`:

```nix
packages = {
  # Cross-platform
  my-package = import ../packages/my-package.nix { inherit pkgs; lib = pkgs.lib; };
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  linux-pkg = import ../packages/linux-pkg.nix { inherit pkgs; lib = pkgs.lib; };
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  darwin-pkg = import ../packages/darwin-pkg.nix { inherit pkgs; lib = pkgs.lib; };
};
```

## Getting Hashes

1. Use `lib.fakeHash` initially in all hash fields
2. Run `nix build .#package-name` — Nix fails with the correct hash
3. Replace `lib.fakeHash` with the provided hash, rebuild
4. For `fetchFromGitHub`: `nix-prefetch-github owner repo --rev v1.0.0`
5. For npm deps: build will fail and provide correct `npmDepsHash`

**Repo requirement**: Track new files before building:
```bash
jj file track packages/new-package.nix
```

## Common Patterns

### makeWrapper
```nix
nativeBuildInputs = [ pkgs.makeWrapper ];
postInstall = ''
  wrapProgram $out/bin/app \
    --prefix PATH : ${lib.makeBinPath [ pkgs.git pkgs.curl ]} \
    --set ENV_VAR "value"
'';
```

### autoPatchelfHook (binary dependencies)
```nix
nativeBuildInputs = [ pkgs.autoPatchelfHook ];
buildInputs = [ pkgs.stdenv.cc.cc.lib ];
```

### substituteInPlace (file patching)
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
| Desktop file not found | Inspect extracted contents — filename often Capitalized |
| Platform error | Check `platforms` in meta, use `optionalAttrs` |
| npm ENOENT / node-gyp | Missing native deps, add `python3` to `nativeBuildInputs` |
| Electron download fails | Set `env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1"` |
| pnpm cache errors | Use `pnpm.fetchDeps` + `pnpm.configHook` |
| Nix can't find .nix file | `jj file track <file>` — flakes require VCS tracking |
| AppImage Exec=AppRun wrong | Check `.desktop` Exec= line — Tauri apps already use correct name |

## Additional Templates

- **Deb packages**: See [references/deb.md](references/deb.md)
- **Node.js** (npm, yarn, pnpm, Electron, native deps): See [references/nodejs.md](references/nodejs.md)
- **Source builds** (stdenv, Python, Go, Rust): See [references/source-builds.md](references/source-builds.md)
