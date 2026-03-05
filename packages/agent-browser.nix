{
  pkgs,
  lib,
}: let
  nodejs = pkgs.nodejs_22;

  # Build the Rust CLI separately
  rustCli = pkgs.rustPlatform.buildRustPackage {
    pname = "agent-browser-cli";
    version = "0.16.3";

    src = pkgs.fetchFromGitHub {
      owner = "vercel-labs";
      repo = "agent-browser";
      tag = "v0.16.3";
      hash = "sha256-JGPKL9dtsO+kukBxuVJRQAggJVstmAPWEHUWIpRRFrM=";
    };

    sourceRoot = "source/cli";

    cargoHash = "sha256-WbvfAhSwFPR/pHrlPQIWVw2kx+YgbIicVhvWugv9mxc=";

    # Auth/credential tests require real filesystem access (home dir, keyring)
    # which is unavailable in the Nix sandbox
    doCheck = false;

    meta = with lib; {
      description = "Native CLI for agent-browser";
      homepage = "https://github.com/vercel-labs/agent-browser";
      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };
in
  pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "agent-browser";
    version = "0.16.3";

    src = pkgs.fetchFromGitHub {
      owner = "vercel-labs";
      repo = "agent-browser";
      tag = "v${finalAttrs.version}";
      hash = "sha256-JGPKL9dtsO+kukBxuVJRQAggJVstmAPWEHUWIpRRFrM=";
    };

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 2;
      hash = "sha256-zoADdGTlawFGGxC1DMnBUD7U3ayPcHRR/MwN5jMbDl8=";
    };

    nativeBuildInputs = [
      nodejs
      pkgs.pnpm_9
      pkgs.pnpmConfigHook
      pkgs.makeWrapper
    ];

    # Prevent Playwright from trying to download browsers in sandbox
    env = {
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";
    };

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/agent-browser
      mkdir -p $out/bin

      # Copy built files
      cp -r dist $out/lib/agent-browser/
      cp -r bin $out/lib/agent-browser/
      cp -r node_modules $out/lib/agent-browser/
      cp package.json $out/lib/agent-browser/

      # Copy skills directory if it exists
      if [ -d skills ]; then
        cp -r skills $out/lib/agent-browser/
      fi

      # Copy the Rust CLI binary
      cp ${rustCli}/bin/agent-browser $out/lib/agent-browser/bin/agent-browser-linux-x64-unwrapped

      # Wrap the native binary to have node in PATH and set PLAYWRIGHT_BROWSERS_PATH
      # The Rust CLI spawns node to run the daemon, so it needs node in PATH
      makeWrapper $out/lib/agent-browser/bin/agent-browser-linux-x64-unwrapped \
        $out/lib/agent-browser/bin/agent-browser-linux-x64 \
        --prefix PATH : "${nodejs}/bin" \
        --set PLAYWRIGHT_BROWSERS_PATH "${pkgs.playwright-driver.browsers}" \
        --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD "1" \
        --set AGENT_BROWSER_HOME "$out/lib/agent-browser"

      # Create main wrapper that invokes the JS wrapper (which then runs the wrapped Rust CLI)
      makeWrapper ${nodejs}/bin/node $out/bin/agent-browser \
        --add-flags "$out/lib/agent-browser/bin/agent-browser.js" \
        --prefix PATH : "${nodejs}/bin" \
        --set PLAYWRIGHT_BROWSERS_PATH "${pkgs.playwright-driver.browsers}" \
        --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD "1" \
        --set AGENT_BROWSER_HOME "$out/lib/agent-browser"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Headless browser automation CLI for AI agents";
      homepage = "https://github.com/vercel-labs/agent-browser";
      license = licenses.asl20;
      platforms = platforms.linux;
      mainProgram = "agent-browser";
    };
  })
