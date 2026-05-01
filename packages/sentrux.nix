{
  pkgs,
  lib,
}: let
  version = "0.5.7";
  inherit (pkgs.stdenv.hostPlatform) system isDarwin;

  grammarSrcs = {
    x86_64-linux = {
      platform = "linux-x86_64";
      hash = "sha256-iEnx6wffP21Ooe1CLY3uS5t5olBoL6VkZnXa5GZVRFQ=";
    };
    aarch64-linux = {
      platform = "linux-aarch64";
      hash = "sha256-8fuLTRD5YvPNynHq9oZi36lx5Q4i07iUfRvCKcQX8lM=";
    };
    aarch64-darwin = {
      platform = "darwin-arm64";
      hash = "sha256-lCoVl/rmwzgj3PcViphQ5LZyWMrfiRAMIMmA/Dq69I8=";
    };
  };

  grammarSrcInfo = grammarSrcs.${system} or (throw "Unsupported system: ${system}");
  grammarSrc = pkgs.fetchurl {
    url = "https://github.com/sentrux/sentrux/releases/download/v${version}/grammars-${grammarSrcInfo.platform}.tar.gz";
    inherit (grammarSrcInfo) hash;
  };

  meta = with lib; {
    description = "Live codebase visualization and structural quality gate for AI-agent-written code";
    homepage = "https://github.com/sentrux/sentrux";
    license = licenses.mit;
    platforms = lib.attrNames grammarSrcs;
    mainProgram = "sentrux";
  };

  # Darwin: prebuilt binary from GitHub releases
  darwinPackage = pkgs.stdenv.mkDerivation {
    pname = "sentrux";
    inherit version meta;

    src = pkgs.fetchurl {
      url = "https://github.com/sentrux/sentrux/releases/download/v${version}/sentrux-darwin-arm64";
      hash = "sha256-MK4aRNRHit8pQBn85tZc5WhsJbyGPrcVsyDFI0kn9sI=";
    };

    dontUnpack = true;

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/bin/plugins
      cp $src $out/bin/sentrux
      chmod +x $out/bin/sentrux
      tar -xzf ${grammarSrc} -C $out/bin/plugins
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/sentrux \
        --set SENTRUX_SKIP_GRAMMAR_DOWNLOAD 1
    '';
  };

  # Linux: build from source
  linuxPackage = pkgs.rustPlatform.buildRustPackage {
    pname = "sentrux";
    inherit version meta;

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
  };
in
  if isDarwin
  then darwinPackage
  else linuxPackage
