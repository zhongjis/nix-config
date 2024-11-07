{
  lib,
  config,
  ...
}: {
  imports = [
    ./aerospace.nix
  ];

  options = {
    darwin-hm-modules.enable =
      lib.mkEnableOption "enable darwin home-manager modules";
  };

  config = lib.mkIf config.darwin-hm-modules.enable {
    aerospace.enable = lib.mkDefault true;
  };
}
