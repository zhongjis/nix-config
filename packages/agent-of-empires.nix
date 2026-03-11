{
  pkgs,
  lib,
}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "agent-of-empires";
  version = "0.15.1";

  src = pkgs.fetchFromGitHub {
    owner = "njbrake";
    repo = "agent-of-empires";
    rev = "v${version}";
    hash = "sha256-lhIUVjb8J6C2VOTXt/0/rTEYv/N/ICxYyyWPHtiDAko=";
  };

  cargoHash = "sha256-OflpOKSelzX5lku6dpsHuX/YjkBZymFCbA7aZv9BS5g=";

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
