{
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "agent-of-empires";
  version = "0.16.1";

  src = pkgs.fetchFromGitHub {
    owner = "njbrake";
    repo = "agent-of-empires";
    rev = "v${version}";
    hash = "sha256-MSvvGYvSi0dc7CAUI9ComAerptq8uEdE//3f03tC7S0=";
  };

  cargoHash = "sha256-wW8mnEUJ3LyzkeBFP3qdfwpuPsqIZmLOxi/lGIj5On8=";

  doCheck = false;

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.perl
    pkgs.cmake
    pkgs.installShellFiles
    pkgs.makeWrapper
  ];

  buildInputs = [pkgs.zlib];

  postInstall = ''
    wrapProgram $out/bin/aoe \
      --prefix PATH : ${lib.makeBinPath [
      pkgs.tmux
      pkgs.git
    ]}

    installShellCompletion --cmd aoe \
      --bash <($out/bin/aoe completion bash) \
      --fish <($out/bin/aoe completion fish) \
      --zsh <($out/bin/aoe completion zsh)
  '';

  meta = with lib; {
    description = "Terminal session manager for AI coding agents";
    homepage = "https://github.com/njbrake/agent-of-empires";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "aoe";
  };
}
