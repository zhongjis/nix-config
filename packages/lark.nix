{
  pkgs,
  lib,
}: let
  pname = "lark";
  version = "7.72.23";

  srcs = {
    x86_64-linux = {
      url = "https://lf16-larkversion.larksuitecdn.com/obj/lark-version-sg/b69ee051/Lark-linux_x64-${version}.deb";
      sha256 = "sha256-cSKhFlj8DqkTkrMkEYNzP4jRrG6ruyO+LLV24MhNrI8=";
    };
    aarch64-linux = {
      url = "https://lf16-larkversion.larksuitecdn.com/obj/lark-version-sg/55b582c7/Lark-linux_arm64-${version}.deb";
      sha256 = "sha256-4hH2kliDzS60SF5bAOBHbdxG5q2G7T+OQM6HQR4Mbtk=";
    };
  };

  srcInfo = srcs.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
  src = pkgs.fetchurl {
    inherit (srcInfo) url sha256;
    name = "Lark-${version}-${pkgs.stdenv.hostPlatform.system}.deb";
  };

  runtimeLibraryPath = lib.makeLibraryPath [
    pkgs.alsa-lib
    pkgs.at-spi2-atk
    pkgs.at-spi2-core
    pkgs.atk
    pkgs.cairo
    pkgs.cups
    pkgs.dbus
    pkgs.expat
    pkgs.fontconfig
    pkgs.freetype
    pkgs.gdk-pixbuf
    pkgs.glib
    pkgs.glibc
    pkgs.gnutls
    pkgs.gtk3
    pkgs.libGL
    pkgs.libappindicator
    pkgs.libcxx
    pkgs.libdbusmenu
    pkgs.libdrm
    pkgs.libgcrypt
    pkgs.libgbm
    pkgs.libglvnd
    pkgs.libnotify
    pkgs.libpulseaudio
    pkgs.libuuid
    pkgs.libx11
    pkgs.libxcb
    pkgs.libxcomposite
    pkgs.libxcursor
    pkgs.libxdamage
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxi
    pkgs.libxkbcommon
    pkgs.libxkbfile
    pkgs.libxrandr
    pkgs.libxrender
    pkgs.libxscrnsaver
    pkgs.libxshmfence
    pkgs.libxtst
    pkgs.nspr
    pkgs.nss
    pkgs.pango
    pkgs.pciutils
    pkgs.pipewire
    pkgs.pixman
    pkgs.stdenv.cc.cc
    pkgs.systemd
    pkgs.wayland
  ];
in
  pkgs.stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.dpkg
      pkgs.jq
      pkgs.makeShellWrapper
    ];

    buildInputs = [
      pkgs.alsa-lib
      pkgs.cups
      pkgs.gtk3
      pkgs.libdrm
      pkgs.libgbm
      pkgs.libgcrypt
      pkgs.libpulseaudio
      pkgs.libxdamage
      pkgs.libxshmfence
      pkgs.libxtst
      pkgs.nspr
      pkgs.nss
    ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      dpkg --fsys-tarfile "$src" | tar --extract
      mkdir -p "$out"
      mv opt usr/share "$out/"

      appRoot="$out/opt/bytedance/lark"
      desktopFile="$out/share/applications/bytedance-lark.desktop"

      jq \
        '.inhouse_update_config_v2.feishu.update_enable = 0
         | .inhouse_update_config_v2.lark.update_enable = 0' \
        "$appRoot/lark_settings" > "$appRoot/lark_settings.tmp"
      mv "$appRoot/lark_settings.tmp" "$appRoot/lark_settings"

      substituteInPlace "$desktopFile" \
        --replace-fail "/usr/bin/bytedance-lark-stable" "lark"

      for executable in "$appRoot/lark" "$appRoot/vulcan/vulcan" "$appRoot/video_conference_sdk"; do
        if [ -x "$executable" ]; then
          wrapProgram "$executable" \
            --set LARK_UPDATE_DISALLOW_AUTO_UPDATE 1 \
            --prefix PATH : ${lib.makeBinPath [pkgs.xdg-utils]} \
            --prefix XDG_DATA_DIRS : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH" \
            --prefix LD_LIBRARY_PATH : "${runtimeLibraryPath}:$appRoot:${pkgs.addDriverRunpath.driverLink}/share"
        fi
      done

      mkdir -p "$out/bin" "$out/share/icons/hicolor"
      ln -s "$appRoot/bytedance-lark" "$out/bin/lark"
      for size in 16 24 32 48 64 128 256; do
        iconDir="$out/share/icons/hicolor/''${size}x''${size}/apps"
        mkdir -p "$iconDir"
        ln -s "$appRoot/product_logo_''${size}.png" "$iconDir/bytedance-lark.png"
      done

      runHook postInstall
    '';

    passthru = {
      inherit srcs;
      updateScript = lib.getExe (pkgs.writeShellApplication {
        name = "update-lark";
        runtimeInputs = [
          pkgs.alejandra
          pkgs.curl
          pkgs.git
          pkgs.jq
          pkgs.nix
          pkgs.python3
        ];
        text = builtins.readFile ../scripts/update-lark-package.sh;
      });
    };

    meta = {
      description = "All-in-one collaboration suite for international teams";
      homepage = "https://www.larksuite.com/";
      downloadPage = "https://www.larksuite.com/en_us/download";
      license = lib.licenses.unfree;
      mainProgram = "lark";
      platforms = builtins.attrNames srcs;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
