{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage {
  pname = "opencode-morph-fast-apply";
  version = "1.9.0";

  src = pkgs.fetchFromGitHub {
    owner = "JRedeker";
    repo = "opencode-morph-fast-apply";
    rev = "0625507c07ac73443ec8780a674778287a4a0c4e";
    sha256 = "sha256-XjZDwSPidAgNZHyIh6VjOiuDrjOeTFdC5fmTK0UZVm8=";
  };

  npmDepsHash = "sha256-N7IgSo6zeUQeXqEdewUoXXSEn6u9CKz5rkELRY3FQiU=";

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
