{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage (finalAttrs: {
  pname = "likec4";
  version = "1.59.3";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/likec4/-/likec4-${finalAttrs.version}.tgz";
    hash = "sha256-/5E84ocmejQ1dY68MuWuoQV4dGJA/MHTT6NnhpwXWi4=";
  };

  sourceRoot = "package";
  nodejs = pkgs.nodejs_24;
  npmDepsHash = "sha256-gy0SNfQEFIwhab+BYjZVIWqRPL76ZhJDd0a7GzPDZ+Y=";
  dontNpmBuild = true;

  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  postPatch = ''
    cp ${./likec4-package-lock.json} package-lock.json
    ${pkgs.nodejs_24}/bin/npm pkg delete devDependencies
    ${pkgs.nodejs_24}/bin/node --input-type=commonjs <<'EOF'
    const fs = require('node:fs');
    const file = 'dist/cli/index.mjs';
    const original = 'webcomponentPrefix:c,title:l,root:i,languageServices:e';
    const replacement = 'webcomponentPrefix:c,title:l,root:i,cacheDir:M(hn(),`.likec4-vite-cache-''${P.pid}`),languageServices:e';
    const source = fs.readFileSync(file, 'utf8');
    const matches = source.split(original).length - 1;
    if (matches !== 1) {
      throw new Error(`Expected one Vite cache patch target, found ''${matches}`);
    }
    fs.writeFileSync(file, source.replace(original, replacement));
    EOF
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [pkgs.gnugrep];
  installCheckPhase = ''
    runHook preInstallCheck
    test -x $out/bin/likec4
    $out/bin/likec4 --version | grep -Fx ${finalAttrs.version}
    runHook postInstallCheck
  '';

  passthru = {
    tests.start = pkgs.runCommand "likec4-start-smoke" {} ''
      workspace="$TMPDIR/workspace"
      log="$TMPDIR/likec4.log"
      main_module="$TMPDIR/main.mjs"
      mkdir -p "$workspace" "$TMPDIR/home" "$TMPDIR/cache"
      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export CI=1

      cat >"$workspace/model.c4" <<'EOF'
      specification {
        element system
      }
      model {
        app = system 'Smoke System'
      }
      views {
        view index of app {
          title 'Smoke View'
          include *
        }
      }
      EOF

      ${finalAttrs.finalPackage}/bin/likec4 start "$workspace" \
        --listen 127.0.0.1 \
        --port 4173 \
        --no-react-hmr \
        --no-build-webcomponent >"$log" 2>&1 &
      server_pid=$!

      cleanup() {
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
      }
      trap cleanup EXIT

      ready=
      for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
        if ! kill -0 "$server_pid" 2>/dev/null; then
          cat "$log"
          exit 1
        fi
        if ${lib.getExe pkgs.gnugrep} -Fq "node_modules/.vite/deps_temp_" "$log"; then
          cat "$log"
          exit 1
        fi
        if ${lib.getExe pkgs.curl} --fail --silent --max-time 1 \
          http://127.0.0.1:4173/src/main >"$main_module"; then
          ready=1
          break
        fi
        ${pkgs.coreutils}/bin/sleep 0.25
      done

      if test -z "$ready"; then
        cat "$log"
        exit 1
      fi

      dependency_path="$(${lib.getExe pkgs.gnugrep} -o 'from "/@fs/[^"]*"' "$main_module" \
        | ${pkgs.coreutils}/bin/head -n 1 \
        | ${pkgs.gnused}/bin/sed 's/^from "//; s/"$//')"
      test -n "$dependency_path"
      ${lib.getExe pkgs.curl} --fail --silent --show-error --max-time 5 \
        "http://127.0.0.1:4173$dependency_path" >/dev/null

      if ! kill -0 "$server_pid" 2>/dev/null || ${lib.getExe pkgs.gnugrep} -Fq "node_modules/.vite/deps_temp_" "$log"; then
        cat "$log"
        exit 1
      fi

      touch "$out"
    '';

    updateScript = lib.getExe (pkgs.writeShellApplication {
      name = "update-likec4";
      runtimeInputs = [
        pkgs.alejandra
        pkgs.coreutils
        pkgs.curl
        pkgs.git
        pkgs.gnutar
        pkgs.jq
        pkgs.nix
        pkgs.nodejs_24
        pkgs.prefetch-npm-deps
        pkgs.python3
      ];
      text = builtins.readFile ../scripts/update-likec4-package.sh;
    });
  };

  meta = {
    description = "Software architecture modeling tool based on the C4 model";
    homepage = "https://likec4.dev";
    license = lib.licenses.mit;
    mainProgram = "likec4";
    platforms = lib.platforms.unix;
  };
})
