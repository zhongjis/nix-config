{
  bun2nix,
  pkgs,
  lib,
}:
bun2nix.mkDerivation {
  pname = "context-mode";
  version = "1.0.169";

  src = pkgs.fetchFromGitHub {
    owner = "mksglu";
    repo = "context-mode";
    rev = "v1.0.169";
    hash = "sha256-1pV56ZB2aqod+C0kb5myuiWLAJ7+opiaurwZZ3BGKYk=";
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

  patches = [
    (pkgs.writeText "disable-pi-version-check.patch" ''
      diff --git a/src/adapters/pi/mcp-bridge.ts b/src/adapters/pi/mcp-bridge.ts
      --- a/src/adapters/pi/mcp-bridge.ts
      +++ b/src/adapters/pi/mcp-bridge.ts
      @@ -885,8 +885,9 @@ export function foregroundBridgeEnv(
         baseEnv: NodeJS.ProcessEnv,
         foreground: boolean,
       ): NodeJS.ProcessEnv {
      -  if (!foreground) return baseEnv;
      -  return { ...baseEnv, CONTEXT_MODE_BRIDGE_IDLE_MS: "0" };
      +  const piBridgeEnv = { ...baseEnv, CONTEXT_MODE_DISABLE_VERSION_CHECK: "1" };
      +  if (!foreground) return piBridgeEnv;
      +  return { ...piBridgeEnv, CONTEXT_MODE_BRIDGE_IDLE_MS: "0" };
       }

       /** Result of bootstrapping the bridge. */
      diff --git a/src/server.ts b/src/server.ts
      --- a/src/server.ts
      +++ b/src/server.ts
      @@ -4953,10 +4953,12 @@ async function main() {
         // (some users keep the MCP server alive 24h+) catch new releases without a
         // restart. `.unref()` lets the process exit normally on SIGTERM regardless
         // of pending intervals.
      -  fetchLatestVersion().then(v => { if (v !== "unknown") _latestVersion = v; });
      -  setInterval(() => {
      -    fetchLatestVersion().then(v => { if (v !== "unknown") _latestVersion = v; });
      -  }, 60 * 60 * 1000).unref();
      +  if (process.env.CONTEXT_MODE_DISABLE_VERSION_CHECK !== "1") {
      +    fetchLatestVersion().then(v => { if (v !== "unknown") _latestVersion = v; });
      +    setInterval(() => {
      +      fetchLatestVersion().then(v => { if (v !== "unknown") _latestVersion = v; });
      +    }, 60 * 60 * 1000).unref();
      +  }

         // Stats heartbeat — keep the statusline truthful while the user works in
         // tools other than MCP (Bash/Read/Edit during long sessions or post-/compact
    '')
  ];

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

    # Rebuild the MCP server bundle after postPatch; Pi spawns this file at runtime.
    node_modules/.bin/esbuild \
      src/server.ts \
      --bundle \
      --platform=node \
      --target=node18 \
      --format=esm \
      --outfile=server.bundle.mjs \
      --external:better-sqlite3 \
      --external:turndown \
      --external:turndown-plugin-gfm \
      --external:@mixmark-io/domino \
      --minify

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
