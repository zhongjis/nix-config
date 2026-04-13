{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage rec {
  pname = "oh-my-codex";
  version = "0.12.5";

  src = pkgs.fetchFromGitHub {
    owner = "Yeachan-Heo";
    repo = "oh-my-codex";
    rev = "v${version}";
    hash = "sha256-z+zVMTulppaGKBusqnVQB0YkgO/7scp9xeZ9BokTPv8=";
  };

  npmDepsHash = "sha256-JIbYDQcHGR5IxuU/C6QUOVCuHZfDvh7di6eJ4l8ju3s=";

  nativeBuildInputs = [pkgs.makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/omx \
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
