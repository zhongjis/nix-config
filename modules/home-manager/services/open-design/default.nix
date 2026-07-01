{
  inputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  openDesignPackages = inputs.open-design.packages.${system};

  # Upstream currently overrides pnpm for package builds, but its
  # fetchPnpmDeps calls still use nixpkgs' older pnpm_10. Keep the deps
  # fetcher on the pnpm version required by Open Design's package.json.
  pnpm_10_33_2 = pkgs.pnpm_10.overrideAttrs (_old: rec {
    version = "10.33.2";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/pnpm/-/pnpm-${version}.tgz";
      hash = "sha256-envPE9f2zrOUbAOXg3PZm+n94cr8MAC9/tTE95EWdhA=";
    };
  });

  fixPnpmDeps = pkg:
    pkg.overrideAttrs (old: {
      pnpmDeps = old.pnpmDeps.override {
        pnpm = pnpm_10_33_2;
      };
    });
in {
  imports = [
    inputs.open-design.homeManagerModules.default
  ];

  services.open-design = {
    enable = true;
    package = fixPnpmDeps openDesignPackages.daemon;
    autoStart = false;

    webFrontend = {
      enable = true;
      package = fixPnpmDeps openDesignPackages.web;
    };
  };
}
