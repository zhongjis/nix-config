{
  inputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  openDesignPackages = inputs.open-design.packages.${system};
in {
  imports = [
    # ponytail: upstream retired its Nix module, which still reads deprecated
    # pkgs.stdenv.is{Darwin,Linux}. Shim them here; vendor or drop the module
    # if the open-design input ever changes.
    ({pkgs, ...} @ args:
      inputs.open-design.homeManagerModules.default (args
        // {
          pkgs =
            pkgs
            // {
              stdenv = pkgs.stdenv // {inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;};
            };
        }))
  ];

  services.open-design = {
    enable = true;
    package = pkgs.open-design-daemon;
    autoStart = true;

    webFrontend = {
      enable = true;
      package = openDesignPackages.web;
    };
  };
}
