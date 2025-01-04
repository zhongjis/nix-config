{
  pkgs,
  config,
  lib,
  ...
}: {
  # reference: https://nixos.wiki/wiki/Fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5-chinese-addons
        fcitx5-nord
      ];
    };
  };

  # fix Fcitx5 Doesn't Start When Using WM
  # reference: https://nixos.wiki/wiki/Fcitx5
  services.xserver.desktopManager.runXdgAutostartIfNone = config.programs.hyprland.enable;
}
