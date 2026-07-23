{
  bun2nix,
  pkgs,
  lib,
}:
bun2nix.mkDerivation {
  pname = "opencode-morph-fast-apply";
  version = "1.10.2";

  src = pkgs.fetchFromGitHub {
    owner = "JRedeker";
    repo = "opencode-morph-fast-apply";
    rev = "0ab744099ab2a2a2b5a5628c7cf1275e673b640b";
    hash = "sha256-y84bdfjTRGlSMXAOa+KIzDSQw6vim2t0hw8wx1pFPkg=";
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
