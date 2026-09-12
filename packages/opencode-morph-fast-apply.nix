{
  bun2nix,
  pkgs,
  lib,
}:
bun2nix.mkDerivation {
  pname = "opencode-morph-fast-apply";
  version = "1.11.0";

  src = pkgs.fetchFromGitHub {
    owner = "JRedeker";
    repo = "opencode-morph-fast-apply";
    rev = "7f347df7d17f13f1f24083de9ae4b9b2d173d1fb";
    hash = "sha256-MzMUlSGLz5diYWwdurE4Cxhb4bWqdm3D1DUE2yVW+PY=";
  };

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./opencode-morph-fast-apply-bun-lock.nix;
  };

  buildPhase = ''
    runHook preBuild
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/opencode-morph-fast-apply
    cp -r . $out/lib/node_modules/opencode-morph-fast-apply/

    runHook postInstall
  '';

  dontRunLifecycleScripts = true;

  meta = {
    description = "OpenCode plugin for Morph Fast Apply - 10x faster code editing";
    homepage = "https://github.com/JRedeker/opencode-morph-fast-apply";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };

  passthru.updateScript = lib.getExe (pkgs.writeShellApplication {
    name = "update-opencode-morph-fast-apply";
    runtimeInputs = [
      bun2nix
      pkgs.alejandra
      pkgs.curl
      pkgs.git
      pkgs.gawk
      pkgs.gnused
      pkgs.coreutils
      pkgs.jq
      pkgs.nix
      pkgs.nix-prefetch-github
      pkgs.python3
    ];
    text = builtins.readFile ../scripts/update-opencode-morph-fast-apply-package.sh;
  });
}
