{
  inputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  openDesignPackages = inputs.open-design.packages.${system};
in {
  imports = [
    inputs.open-design.homeManagerModules.default
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
