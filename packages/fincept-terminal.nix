{
  pkgs,
  lib,
}: let
  pname = "fincept-terminal";
  version = "4.0.2";

  src = pkgs.fetchurl {
    url = "https://github.com/Fincept-Corporation/FinceptTerminal/releases/download/v${version}/FinceptTerminal-${version}-linux-x64-setup.run";
    sha256 = "sha256-TIjfjwCHAMxZX1rbKgsBnqA7WZjt7Sf2I5sBisBcIzg=";
    name = "${pname}-${version}.AppImage";
  };

  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
  };
in
  pkgs.appimageTools.wrapType2 rec {
    inherit pname version src;

    extraPkgs = pkgs: [];

    extraInstallCommands = ''
      # Install desktop file and icons from extracted AppImage
      install -Dm644 ${appimageContents}/fincept-terminal.desktop \
        $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail "Exec=FinceptTerminal" "Exec=${pname}"

      install -Dm644 ${appimageContents}/fincept-terminal.png \
        $out/share/icons/hicolor/256x256/apps/${pname}.png
    '';

    meta = with lib; {
      description = "A modern financial terminal for market analysis and trading workflows";
      homepage = "https://github.com/Fincept-Corporation/FinceptTerminal";
      license = licenses.agpl3Plus;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
      sourceProvenance = [sourceTypes.binaryNativeCode];
    };
  }
