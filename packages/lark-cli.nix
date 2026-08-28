{
  pkgs,
  lib,
}: let
  pname = "lark-cli";
  version = "1.0.91";

  srcs = {
    x86_64-linux = {
      arch = "amd64";
      sha256 = "sha256-rY6I49ToOReJ2yMztlAx0N6BWgoJk97zxNJLI2oohOs=";
    };
    aarch64-linux = {
      arch = "arm64";
      sha256 = "sha256-aSGRPqJ34ZFTObp81HHh9gesw6ApIBDWKu8TYIGKTss=";
    };
  };

  srcInfo = srcs.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
  src = pkgs.fetchurl {
    url = "https://github.com/larksuite/cli/releases/download/v${version}/lark-cli-${version}-linux-${srcInfo.arch}.tar.gz";
    inherit (srcInfo) sha256;
  };
in
  pkgs.stdenvNoCC.mkDerivation {
    inherit pname version src;

    sourceRoot = ".";
    dontBuild = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 lark-cli "$out/bin/lark-cli"
      install -Dm644 LICENSE "$out/share/licenses/${pname}/LICENSE"
      install -Dm644 README.md "$out/share/doc/${pname}/README.md"
      install -Dm644 CHANGELOG.md "$out/share/doc/${pname}/CHANGELOG.md"

      runHook postInstall
    '';

    doInstallCheck = pkgs.stdenv.hostPlatform.canExecute pkgs.stdenv.buildPlatform;
    installCheckPhase = ''
      runHook preInstallCheck
      "$out/bin/lark-cli" --version | grep -F "lark-cli version ${version}"
      runHook postInstallCheck
    '';

    passthru = {
      inherit srcs;
      updateScript = lib.getExe (pkgs.writeShellApplication {
        name = "update-lark-cli";
        runtimeInputs = [
          pkgs.alejandra
          pkgs.curl
          pkgs.git
          pkgs.jq
          pkgs.nix
          pkgs.python3
        ];
        text = builtins.readFile ../scripts/update-lark-cli-package.sh;
      });
    };

    meta = {
      description = "Official CLI for the Lark and Feishu Open Platform";
      homepage = "https://github.com/larksuite/cli";
      changelog = "https://github.com/larksuite/cli/releases/tag/v${version}";
      license = lib.licenses.mit;
      mainProgram = "lark-cli";
      platforms = builtins.attrNames srcs;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
