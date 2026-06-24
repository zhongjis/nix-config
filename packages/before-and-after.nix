{
  agentBrowser,
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "before-and-after";
  version = "0.0.4";

  gitHead = "c9bb2a5c7dead64a3663e50bf97e443914ea334b";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@vercel/before-and-after/-/before-and-after-${finalAttrs.version}.tgz";
    hash = "sha256-NKfm9BhEFMnR6nKoRcLJgkuR4T56Wi2k64yiml5zj2E=";
  };

  sourceRoot = "package";

  nativeBuildInputs = [pkgs.makeWrapper];

  installPhase = ''
    runHook preInstall

    package_dir="$out/lib/node_modules/@vercel/before-and-after"
    install -d "$package_dir" "$out/bin"
    cp -r dist skill "$package_dir/"
    install -m644 package.json README.md LICENSE "$package_dir/"

    makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/before-and-after" \
      --add-flags "$package_dir/dist/bin/cli.js" \
      --prefix PATH : ${lib.makeBinPath [agentBrowser]}

    runHook postInstall
  '';

  passthru.upstreamLicense = "PolyForm-Shield-1.0.0";

  passthru.updateScript = lib.getExe (pkgs.writeShellApplication {
    name = "update-before-and-after";
    runtimeInputs = [
      pkgs.curl
      pkgs.git
      pkgs.jq
      pkgs.nix
      pkgs.python3
      pkgs.gnutar
      pkgs.alejandra
    ];
    text = builtins.readFile ../scripts/update-before-and-after-package.sh;
  });

  meta = {
    description = "Simple before/after screenshot tool for capturing and comparing web pages";
    homepage = "https://github.com/vercel-labs/before-and-after";
    mainProgram = "before-and-after";
    platforms = lib.platforms.unix;
  };
})
