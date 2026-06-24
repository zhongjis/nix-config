{
  pkgs,
  lib,
}: let
  version = "0.13.1.1";

  # Map from Nix system to architecture suffix and hash
  srcs = {
    x86_64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
      sha256 = "sha256-ZAU+IHSuKu8KiqtgK+fe914C/y7KToVWzC+drqdk+ZM=";
    };
    aarch64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64.AppImage";
      sha256 = "sha256-wfCUiHq++Wgq1PySt0aa3thrBSKg+7RQqod/Pudgdps=";
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
