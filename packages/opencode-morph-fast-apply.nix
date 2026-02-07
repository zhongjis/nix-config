{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "opencode-morph-fast-apply";
  version = "1.5.0";

  src = pkgs.fetchFromGitHub {
    owner = "JRedeker";
    repo = "opencode-morph-fast-apply";
    rev = "4ba0d8f12417a9cf9b23a1fde62b47f4e1d18e1e";
    sha256 = "sha256-0Ex1OnwhkZB9eZz2ZAK8pxGUVGIkIiaaiDhrkG29rN0=";
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
