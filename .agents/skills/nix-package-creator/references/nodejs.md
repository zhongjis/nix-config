# Node.js Package Templates

Templates for packaging Node.js applications (npm, yarn, pnpm, Electron).

## Table of Contents

- [buildNpmPackage (npm)](#buildnpmpackage-npm)
- [Electron Applications](#electron-applications)
- [pnpm Projects](#pnpm-projects)
- [Yarn Projects](#yarn-projects)
- [Native Dependencies](#native-dependencies)

## buildNpmPackage (npm)

```nix
{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage rec {
  pname = "my-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = pname;
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  npmDepsHash = lib.fakeHash;

  # If package.json has no build script, skip
  # dontNpmBuild = true;

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/my-app";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
```

**Hash workflow**: Build once → get correct `hash` → update → build again → get correct `npmDepsHash` → update → build succeeds.

## Electron Applications

```nix
{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage rec {
  pname = "electron-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = pname;
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  npmDepsHash = lib.fakeHash;

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  nativeBuildInputs = [ pkgs.makeWrapper ];

  postInstall = ''
    makeWrapper ${pkgs.electron}/bin/electron $out/bin/${pname} \
      --add-flags $out/lib/node_modules/${pname}/dist/main.js
  '';

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/electron-app";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
```

**Key**: `ELECTRON_SKIP_BINARY_DOWNLOAD` prevents Electron from downloading its own binary — use the nixpkgs `electron` package instead.

## pnpm Projects

```nix
{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "pnpm-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = "pnpm-app";
    rev = "v${finalAttrs.version}";
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [
    pkgs.nodejs
    pkgs.pnpm.configHook
  ];

  pnpmDeps = pkgs.pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = lib.fakeHash;
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp -r dist $out/lib/${finalAttrs.pname}
    runHook postInstall
  '';

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/pnpm-app";
    license = lib.licenses.mit;
  };
})
```

**Real example**: `packages/agent-browser.nix` uses this pattern with `pnpm.fetchDeps` + `pnpm.configHook`.

## Yarn Projects

```nix
{
  pkgs,
  lib,
}:
pkgs.mkYarnPackage {
  pname = "yarn-app";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "author";
    repo = "yarn-app";
    rev = "v1.0.0";
    hash = lib.fakeHash;
  };

  packageJSON = ./package.json;
  yarnLock = ./yarn.lock;

  buildPhase = ''
    runHook preBuild
    yarn --offline build
    runHook postBuild
  '';

  meta = {
    description = "Short description";
    homepage = "https://github.com/author/yarn-app";
    license = lib.licenses.mit;
  };
}
```

## Native Dependencies

When Node.js packages have native addons (node-gyp, sharp, etc.):

```nix
nativeBuildInputs = [
  pkgs.python3        # node-gyp requires Python
  pkgs.pkg-config     # for finding native libs
];

buildInputs = [
  pkgs.vips           # example: for sharp image library
  pkgs.libpng
  pkgs.libjpeg
];
```

Common native deps:
- `sharp` → `pkgs.vips`
- `canvas` → `pkgs.cairo`, `pkgs.pango`, `pkgs.libjpeg`
- `sqlite3` → `pkgs.sqlite`
- `bcrypt` → included in stdenv
- `node-gyp` itself → `pkgs.python3`
