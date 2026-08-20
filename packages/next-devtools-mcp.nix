{
  pkgs,
  lib,
}: let
  pname = "next-devtools-mcp";
  version = "0.4.0";

  src = pkgs.fetchFromGitHub {
    owner = "vercel";
    repo = "next-devtools-mcp";
    rev = "v${version}";
    hash = "sha256-jLT5UL+OKirZp92TyZJyX6iJ6vB779PnyKdrxWwyQVU=";
  };
in
  pkgs.stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit pname version src;
      fetcherVersion = 3;
      hash = "sha256-q0hrHKfgU90MDobS3HCdPi5oWqiYzhzI2kCEJd+J15E=";
    };

    nativeBuildInputs = [
      pkgs.nodejs_22
      pkgs.makeWrapper
      pkgs.pnpm
      pkgs.pnpmConfigHook
    ];

    buildPhase = ''
      runHook preBuild

      pnpm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/node_modules/${pname} $out/bin
      cp -r dist node_modules package.json $out/lib/node_modules/${pname}/
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/next-devtools-mcp \
        --add-flags $out/lib/node_modules/${pname}/dist/index.js

      runHook postInstall
    '';

    passthru.updateScript = pkgs.nix-update-script {extraArgs = ["--flake"];};

    meta = {
      description = "Next.js development tools MCP server with stdio transport";
      homepage = "https://github.com/vercel/next-devtools-mcp";
      license = lib.licenses.mit;
      mainProgram = "next-devtools-mcp";
      platforms = lib.platforms.unix;
    };
  }
