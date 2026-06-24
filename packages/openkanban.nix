{
  pkgs,
  lib,
}:
pkgs.buildGoModule rec {
  pname = "openkanban";
  version = "0.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "TechDufus";
    repo = "openkanban";
    rev = "v${version}";
    hash = "sha256-86Q70Qh5AMaTX3ogDZl2+V6KCQA5HZjpRcqBmfEucm4=";
  };

  vendorHash = "sha256-ziBcns1wN5p1gp7hSh3+1d05OnZZqHlvcXJtsfEXq6s=";

  nativeBuildInputs = [pkgs.makeWrapper];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  postInstall = ''
    wrapProgram $out/bin/openkanban \
      --prefix PATH : ${lib.makeBinPath [pkgs.git]}
  '';

  meta = with lib; {
    description = "TUI kanban board for orchestrating AI coding agents";
    homepage = "https://github.com/TechDufus/openkanban";
    license = licenses.agpl3Only;
    platforms = platforms.unix;
    mainProgram = "openkanban";
  };

  passthru.updateScript = pkgs.nix-update-script {extraArgs = ["--flake"];};
}
