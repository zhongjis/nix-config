{
  pkgs,
  lib,
}:
pkgs.buildNpmPackage (finalAttrs: {
  pname = "likec4";
  version = "1.59.3";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/likec4/-/likec4-${finalAttrs.version}.tgz";
    hash = "sha256-/5E84ocmejQ1dY68MuWuoQV4dGJA/MHTT6NnhpwXWi4=";
  };

  sourceRoot = "package";
  nodejs = pkgs.nodejs_24;
  npmDepsHash = "sha256-gy0SNfQEFIwhab+BYjZVIWqRPL76ZhJDd0a7GzPDZ+Y=";
  dontNpmBuild = true;

  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  postPatch = ''
    cp ${./likec4-package-lock.json} package-lock.json
    ${pkgs.nodejs_24}/bin/npm pkg delete devDependencies
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [pkgs.gnugrep];
  installCheckPhase = ''
    runHook preInstallCheck
    test -x $out/bin/likec4
    $out/bin/likec4 --version | grep -Fx ${finalAttrs.version}
    runHook postInstallCheck
  '';

  passthru.updateScript = lib.getExe (pkgs.writeShellApplication {
    name = "update-likec4";
    runtimeInputs = [
      pkgs.alejandra
      pkgs.coreutils
      pkgs.curl
      pkgs.git
      pkgs.gnutar
      pkgs.jq
      pkgs.nix
      pkgs.nodejs_24
      pkgs.prefetch-npm-deps
      pkgs.python3
    ];
    text = builtins.readFile ../scripts/update-likec4-package.sh;
  });

  meta = {
    description = "Software architecture modeling tool based on the C4 model";
    homepage = "https://likec4.dev";
    license = lib.licenses.mit;
    mainProgram = "likec4";
    platforms = lib.platforms.unix;
  };
})
