{
  bun2nix,
  pkgs,
  lib,
}:
bun2nix.mkDerivation {
  pname = "context-mode";
  version = "1.0.168";

  src = pkgs.fetchFromGitHub {
    owner = "mksglu";
    repo = "context-mode";
    rev = "v1.0.168";
    hash = "sha256-M0FC1r3J3EF8XSNT6+IuaG7l69pnyQB80dYh5a+cSLk=";
  };

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun-lock.nix;
  };

  # Skip bun2nix's global lifecycle-scripts phase: it would run context-mode's
  # own root `postinstall` (scripts/postinstall.mjs), which heals registries
  # and rewrites paths over the network — unusable in the sandbox. We build the
  # one native dependency (better-sqlite3) explicitly below instead.
  dontRunLifecycleScripts = true;

  # Use the copy backend so node_modules is writable; the default symlink/
  # hardlink backends point node_modules entries at the read-only store cache,
  # which blocks the in-tree native build of better-sqlite3.
  bunInstallFlags = "--linker=isolated --backend=copyfile";

  nativeBuildInputs =
    [
      # The native better-sqlite3 addon is a V8-ABI module (not N-API), so its
      # NODE_MODULE_VERSION is tied to the Node major it is compiled against. Pi
      # itself runs on Node 24, so the addon MUST be built against Node 24 to load
      # in-process. node-gyp ships its own Node, so we invoke it under nodejs_24
      # explicitly rather than relying on node-gyp's bundled runtime.
      pkgs.nodejs_24
      pkgs.python3
      pkgs.node-gyp
    ]
    # libtool from cctools is only needed for the Mach-O static archive step on
    # darwin; on Linux node-gyp archives better-sqlite3 with ar from stdenv.
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [pkgs.cctools];

  buildPhase = ''
    runHook preBuild

    # node_modules entries copied from the read-only store cache come in
    # read-only; make them writable so the in-tree native build can run.
    chmod -R u+rwx node_modules

    export npm_config_nodedir=${pkgs.nodejs_24}

    # Compile the native better-sqlite3 addon from source (no prebuilt
    # download in the sandbox). The pi extension and the spawned
    # server.bundle.mjs both require it at runtime. Run node-gyp under
    # nodejs_24 so the produced binding targets Node 24's ABI (137).
    ( cd node_modules/better-sqlite3 \
      && ${pkgs.nodejs_24}/bin/node \
         ${pkgs.node-gyp}/lib/node_modules/node-gyp/bin/node-gyp.js \
         rebuild --release --nodedir=${pkgs.nodejs_24} )

    # Compile TypeScript -> build/, producing build/adapters/pi/extension.js
    # (the entry point declared in package.json's "pi" manifest).
    node_modules/.bin/tsc -p tsconfig.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    # Package root layout the pi adapter resolves at runtime:
    #   build/adapters/pi/extension.js  -> pluginRoot = $out
    #   $out/server.bundle.mjs, $out/hooks/*.mjs, $out/skills
    for item in \
      package.json \
      build \
      hooks \
      configs \
      skills \
      bin \
      scripts \
      server.bundle.mjs \
      cli.bundle.mjs \
      start.mjs \
      node_modules; do
      if [ -e "$item" ]; then
        cp -r "$item" "$out/"
      fi
    done

    runHook postInstall
  '';

  meta = {
    description = "MCP plugin that saves context window via sandboxed code execution and FTS5 search";
    homepage = "https://github.com/mksglu/context-mode";
    license = lib.licenses.elastic20;
    platforms = lib.platforms.unix;
  };
}
