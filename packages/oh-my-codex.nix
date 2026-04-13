{
  pkgs,
  lib,
}:
let
  version = "0.12.6";

  src = pkgs.fetchFromGitHub {
    owner = "Yeachan-Heo";
    repo = "oh-my-codex";
    rev = "v${version}";
    hash = "sha256-Q2Z8aITmEg+yNoRxCMMAie9nuZmLUXVhqc7Tea7zV9w=";
  };

  # Rust-native helper binaries shipped alongside the Node.js CLI.
  # omx-explore-harness  → powers `omx explore`   (env: OMX_EXPLORE_BIN)
  # omx-sparkshell       → powers `omx sparkshell` (env: OMX_SPARKSHELL_BIN)
  rustBinaries = pkgs.rustPlatform.buildRustPackage {
    pname = "oh-my-codex-native";
    inherit version src;

    cargoLock.lockFile = "${src}/Cargo.lock";

    # Only compile the two binaries that the CLI delegates to.
    cargoBuildFlags = ["-p" "omx-explore-harness" "-p" "omx-sparkshell"];

    doCheck = false;
  };
in
pkgs.buildNpmPackage rec {
  pname = "oh-my-codex";
  inherit version src;

  npmDepsHash = "sha256-HgrC4uLtZ38x6myCu8AbrghrZi4aXod0A6/b19GZ4ro=";

  nativeBuildInputs = [pkgs.makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/omx \
      --set OMX_EXPLORE_BIN ${rustBinaries}/bin/omx-explore-harness \
      --set OMX_SPARKSHELL_BIN ${rustBinaries}/bin/omx-sparkshell \
      --set OMX_NATIVE_AUTO_FETCH 0 \
      --prefix PATH : ${lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.findutils
        pkgs.git
        pkgs.gnugrep
        pkgs.gnused
        pkgs.tmux
      ]}
  '';

  meta = with lib; {
    description = "Workflow layer for OpenAI Codex CLI with prompts, skills, and team orchestration";
    homepage = "https://github.com/Yeachan-Heo/oh-my-codex";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "omx";
  };
}
