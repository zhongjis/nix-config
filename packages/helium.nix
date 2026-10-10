{
  pkgs,
  lib,
}: let
  version = "0.19.2.1";

  # Map from Nix system to architecture suffix and hash
  srcs = {
    x86_64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
      sha256 = "sha256-oEVQo8fHC9rTrNOkQw7ajSr8C/cXOpxYpAP+q5UXCH8=";
    };
    aarch64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64.AppImage";
      sha256 = "sha256-1X5njYlqQrEB7v7BU//ClgoHSNNopq+8U9bE3hbMYDQ=";
    };
  };

  srcInfo = srcs.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  src = pkgs.fetchurl {
    url = srcInfo.url;
    sha256 = srcInfo.sha256;
    name = "helium-${version}-${pkgs.stdenv.hostPlatform.system}.AppImage";
  };

  # Extract AppImage contents
  appimageContents = pkgs.appimageTools.extract {
    pname = "helium";
    inherit version src;
  };
in
  pkgs.appimageTools.wrapType2 rec {
    pname = "helium";
    inherit version src;

    extraPkgs = pkgs: [];

    extraInstallCommands = ''
      # Install desktop file and icons from extracted AppImage
      mkdir -p $out/share/applications
      cp ${appimageContents}/helium.desktop $out/share/applications/

      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp ${appimageContents}/helium.png $out/share/icons/hicolor/256x256/apps/
    '';

    meta = with lib; {
      description = "Helium - A fast, lightweight web browser";
      homepage = "https://github.com/imputnet/helium-linux";
      license = licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "helium";
    };

    passthru.updateScript = lib.getExe (pkgs.writeShellApplication {
      name = "update-helium";
      runtimeInputs = [
        pkgs.curl
        pkgs.git
        pkgs.jq
        pkgs.nix
        pkgs.python3
        pkgs.alejandra
      ];
      text = builtins.readFile ../scripts/update-helium-package.sh;
    });
  }
