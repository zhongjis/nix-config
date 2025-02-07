{
  pkgs,
  lib,
  config,
  inputs,
  currentSystem,
  isDarwin,
  ...
}: {
  home.packages =
    if isDarwin
    then [
      pkgs.nerd-fonts.jetbrains-mono
    ]
    else [
      pkgs.nerd-fonts.jetbrains-mono
      inputs.ghostty.packages.${currentSystem}.default
    ];

  myHomeManager.fastfetch.enable = lib.mkForce true;

  home.file."${config.xdg.configHome}/ghostty/config" = {
    text =
      /*
      toml
      */
      ''
        font-family = JetBrainsMono Nerd Font
        font-size = 14
        theme = catppuccin-mocha
        window-decoration = false
        window-padding-x = 18
        window-padding-y = 12
        initial-command = zsh -l -c 'tmux attach || tmux new-session -d -s home "fastfetch; exec $SHELL" && tmux attach -t home'
        confirm-close-surface = false
        background-opacity = 0.9
      '';
  };
}
