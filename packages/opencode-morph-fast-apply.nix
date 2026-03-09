{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "opencode-morph-fast-apply";
  version = "1.8.2";

  src = pkgs.fetchFromGitHub {
    owner = "JRedeker";
    repo = "opencode-morph-fast-apply";
    rev = "8a5171c4bf50b4df53a76101395a3920fae2dfc9";
    sha256 = "sha256-gAEtyr0vrmEQT63yM4FWGN+SkZaJVuJFVTun2hYBPQk=";
  };

  npmDepsHash = "sha256-hn2DAfQGpwoGIzNjrhV+ijU4ZRRvx9HQZcqYdwAqiss=";

  # This is a TypeScript plugin that runs directly via Bun
  # No build step needed - just install deps
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-morph-fast-apply
    cp -r . $out/lib/node_modules/opencode-morph-fast-apply/

    runHook postInstall
  '';

  meta = {
    description = "OpenCode plugin for Morph Fast Apply - 10x faster code editing";
    homepage = "https://github.com/JRedeker/opencode-morph-fast-apply";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
