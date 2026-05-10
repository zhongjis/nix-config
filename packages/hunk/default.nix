{
  bun2nix,
  pkgs,
  lib,
}:
bun2nix.mkDerivation {
  pname = "hunk";
  version = "0.9.5";

  src = pkgs.fetchFromGitHub {
    owner = "modem-dev";
    repo = "hunk";
    rev = "v0.9.5";
    hash = "sha256-Ug8H4TndLbaOfYGpU5QfkIJdh0GEwCwjyePi8JoVzR8=";
  };

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun-lock.nix;
  };

  buildPhase = ''
    runHook preBuild
    mkdir -p .bun-tmp .bun-install
    BUN_TMPDIR=$PWD/.bun-tmp \
      BUN_INSTALL=$PWD/.bun-install \
      bun build --compile ./src/main.tsx --outfile hunk-bin
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 hunk-bin $out/bin/hunk
    cp -r skills $out/
    runHook postInstall
  '';

  dontFixup = true;
  dontStrip = true;
  dontRunLifecycleScripts = true;

  meta = {
    description = "Review-first terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = lib.platforms.unix;
  };
}
