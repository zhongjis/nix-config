{
  pkgs,
  lib,
}: let
  version = "0.5.7";
  grammarSrcs = {
    x86_64-linux = {
      platform = "linux-x86_64";
      hash = "sha256-iEnx6wffP21Ooe1CLY3uS5t5olBoL6VkZnXa5GZVRFQ=";
    };
    aarch64-linux = {
      platform = "linux-aarch64";
      hash = "sha256-8fuLTRD5YvPNynHq9oZi36lx5Q4i07iUfRvCKcQX8lM=";
    };
  };
  grammarSrcInfo = grammarSrcs.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
  grammarSrc = pkgs.fetchurl {
    url = "https://github.com/sentrux/sentrux/releases/download/v${version}/grammars-${grammarSrcInfo.platform}.tar.gz";
    inherit (grammarSrcInfo) hash;
  };
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "sentrux";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "sentrux";
      repo = "sentrux";
      rev = "v${version}";
      hash = "sha256-6eudX78Aiiti1Ddhj4vhyPjR5Eyu8MiLndcHz2ftqpY=";
    };

    cargoHash = "sha256-T6CIPIgNzr1eZPrUwUaHZggNuwKagjyrd6LeKstjxb0=";

    # Upstream parser tests fail in the Nix sandbox despite the binary building successfully.
    doCheck = false;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.pkg-config
      pkgs.wrapGAppsHook3
    ];

    buildInputs = [
      pkgs.gsettings-desktop-schemas
      pkgs.gtk3
      pkgs.libgit2
      pkgs.libglvnd
      pkgs.libxkbcommon
      pkgs.openssl
      pkgs.wayland
      pkgs.libx11
      pkgs.libxcursor
      pkgs.libxi
      pkgs.libxrandr
      pkgs.libxcb
    ];

    dontWrapGApps = true;

    postInstall = ''
      mkdir -p $out/bin/plugins
      tar -xzf ${grammarSrc} -C $out/bin/plugins
    '';

    postFixup = ''
      gappsWrapperArgs+=(
        --set SENTRUX_SKIP_GRAMMAR_DOWNLOAD 1
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.libglvnd]}:/run/opengl-driver/lib"
      )
      wrapProgram $out/bin/sentrux "''${gappsWrapperArgs[@]}"
    '';

    meta = with lib; {
      description = "Live codebase visualization and structural quality gate for AI-agent-written code";
      homepage = "https://github.com/sentrux/sentrux";
      license = licenses.mit;
      platforms = attrNames grammarSrcs;
      mainProgram = "sentrux";
    };
  }
