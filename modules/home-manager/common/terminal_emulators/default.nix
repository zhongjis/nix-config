{
  lib,
  config,
  ...
}: {
  imports = [
    ./alacritty.nix
    ./kitty.nix
  ];

  options = {
    terminal_emulator.enable =
      lib.mkEnableOption "enable terminal emulators";
  };

  config = lib.mkIf config.terminal_emulator.enable {
    alacritty.enable = lib.mkDefault false;
    kitty.enable = lib.mkDefault true;
  };
}
