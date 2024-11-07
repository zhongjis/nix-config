{
  lib,
  config,
  ...
}: {
  imports = [
    ./aerospace.nix
  ];

  options = {
    nix-darwin-hm-modules.enable =
      lib.mkEnableOption "enable nix-darwin home-manager modules";
  };

  config = lib.mkIf config.nix-darwin-hm-modules.enable {
    aerospace.enable = lib.mkDefault true;
  };
}
