{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "opencode-morph-fast-apply";
  version = "1.8.0";

  src = pkgs.fetchFromGitHub {
    owner = "JRedeker";
    repo = "opencode-morph-fast-apply";
    rev = "f67e0a8ade191fe57f491dbad526a253eac4df2d";
    sha256 = "sha256-m7CIvl9izv5m2eCKijcaIrokVYAs5OEgavEsyMD4VrQ=";
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
