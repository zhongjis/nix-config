{
  pkgs,
  lib,
}: let
  version = "2.0.9.0";

  # Map from Nix system to architecture suffix and hash
  srcs = {
    x86_64-linux = {
      url = "https://github.com/DevToys-app/DevToys/releases/download/${version}/devtoys_linux_x64.deb";
      sha256 = "sha256-Nt0olrd9iiV0ezvH99UMhdYG3kymhkGhISG4apdFK/U=";
    };
    aarch64-linux = {
      url = "https://github.com/DevToys-app/DevToys/releases/download/${version}/devtoys_linux_arm.deb";
      sha256 = "sha256-VbErAQgQXR5mIVNT+7pUClUGEeWpUOTeQPNqdyKCQEs=";
    };
  };

  srcInfo = srcs.${pkgs.system} or (throw "Unsupported system: ${pkgs.system}");

  src = pkgs.fetchurl {
    url = srcInfo.url;
    sha256 = srcInfo.sha256;
    name = "devtoys-${version}-${pkgs.system}.deb";
  };

  pkgs.stdenv.mkDerivation rec {
    pname = "devtoys";
    inherit version src;

    nativeBuildInputs = [
      pkgs.dpkg
      pkgs.makeWrapper
    ];

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;

    unpackCmd = "dpkg-deb -x $src";

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share

      # Copy usr and opt directories from extracted .deb
      cp -r usr/* $out/
      cp -r opt/* $out/

      # Fix desktop file
      if [ -f "$out/share/applications/devtoys.desktop" ]; then
        substituteInPlace $out/share/applications/devtoys.desktop \
          --replace-fail 'Exec=/usr/bin/DevToys' 'Exec=devtoys' \
          --replace-fail 'Icon=/opt/devtoys/devtoys/Icon-Windows-Linux-Preview.png' 'Icon=$out/opt/devtoys/devtoys/Icon-Windows-Linux-Preview.png'
      fi

      # Wrap main binary
      if [ -f "$out/opt/devtoys/devtoys/DevToys.Linux" ]; then
        makeWrapper $out/opt/devtoys/devtoys/DevToys.Linux $out/bin/devtoys \
          --chdir $out/opt/devtoys/devtoys
      else
        echo "Warning: Could not find DevToys binary at $out/opt/devtoys/devtoys/DevToys.Linux"
        exit 1
      fi
    '';

    meta = with lib; {
      description = "DevToys - A Swiss Army knife for developers. Smart code generator, converter, decoder, and more.";
      homepage = "https://github.com/DevToys-app/DevToys";
      license = licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "devtoys";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  }
