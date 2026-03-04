# Source Build Templates

Templates for packaging software built from source using stdenv, Python, Go, and Rust.

## Table of Contents

- [Generic stdenv (C/C++/Meson/CMake)](#generic-stdenv)
- [Python (buildPythonApplication)](#python)
- [Go (buildGoModule)](#go)
- [Rust (rustPlatform.buildRustPackage)](#rust)

## Generic stdenv

```nix
{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation {
  pname = "my-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = "my-app";
    rev = "v1.0.0";
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [
    pkgs.cmake        # or pkgs.meson + pkgs.ninja
    pkgs.pkg-config
  ];

  buildInputs = [
    # Runtime libraries the app links against
  ];

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/my-app";
    license = lib.licenses.mit;
    mainProgram = "my-app";
  };
}
```

Build systems:
- **Autotools**: no extra `nativeBuildInputs` (stdenv handles `./configure && make`)
- **CMake**: add `pkgs.cmake`
- **Meson**: add `pkgs.meson` + `pkgs.ninja`
- **Custom**: override `buildPhase` and `installPhase`

## Python

```nix
{
  pkgs,
  lib,
}:
pkgs.python3Packages.buildPythonApplication {
  pname = "my-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = "my-app";
    rev = "v1.0.0";
    hash = lib.fakeHash;
  };

  pyproject = true;

  build-system = [
    pkgs.python3Packages.setuptools
    # or: pkgs.python3Packages.hatchling
    # or: pkgs.python3Packages.poetry-core
  ];

  dependencies = [
    pkgs.python3Packages.requests
    pkgs.python3Packages.click
  ];

  # For libraries (not applications), use buildPythonPackage instead

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/my-app";
    license = lib.licenses.mit;
    mainProgram = "my-app";
  };
}
```

Key notes:
- `pyproject = true` for modern `pyproject.toml`-based projects
- `build-system` replaces the old `nativeBuildInputs` for Python build backends
- `dependencies` replaces the old `propagatedBuildInputs`
- Use `buildPythonPackage` for libraries, `buildPythonApplication` for executables

## Go

```nix
{
  pkgs,
  lib,
}:
pkgs.buildGoModule {
  pname = "my-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = "my-app";
    rev = "v1.0.0";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;
  # If vendor/ is committed: vendorHash = null;

  ldflags = [
    "-s" "-w"
    "-X main.version=1.0.0"
  ];

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/my-app";
    license = lib.licenses.mit;
    mainProgram = "my-app";
  };
}
```

Key notes:
- `vendorHash` = hash of Go module dependencies (use `lib.fakeHash` first, build to get correct hash)
- If the repo vendors dependencies (has `vendor/` dir), set `vendorHash = null`
- `ldflags` for setting version info at compile time (common Go pattern)

## Rust

```nix
{
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "my-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = "my-app";
    rev = "v1.0.0";
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  nativeBuildInputs = [
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.openssl
  ];

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/my-app";
    license = lib.licenses.mit;
    mainProgram = "my-app";
  };
}
```

Key notes:
- `cargoHash` = hash of Cargo dependencies (use `lib.fakeHash` first)
- Common `buildInputs`: `openssl`, `sqlite`, `libgit2`
- Add `pkgs.pkg-config` to `nativeBuildInputs` when linking C libraries
- For workspace builds with multiple binaries, use `cargoBuildFlags = [ "-p" "specific-crate" ]`
