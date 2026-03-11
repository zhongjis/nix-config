{
  pkgs,
  lib,
}:
pkgs.buildGoModule rec {
  pname = "openkanban";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "TechDufus";
    repo = "openkanban";
    rev = "v${version}";
    hash = "sha256-R0UbJiiE9jrWTtyUYooxC1/8W5H2HCquNJAwGwY5ASk=";
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
}
