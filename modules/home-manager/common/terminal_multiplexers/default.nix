{
  lib,
  config,
  ...
}: {
  imports = [
    ./tmux
    ./zellij
  ];

  options = {
    terminal_multiplexer.enable =
      lib.mkEnableOption "enable terminal_multiplexer";
  };

  config = lib.mkIf config.terminal_multiplexer.enable {
    tmux.enable = lib.mkDefault true;
    zellij.enable = lib.mkDefault false;
  };
}
