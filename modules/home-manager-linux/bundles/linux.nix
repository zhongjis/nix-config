{
  pkgs,
  lib,
  ...
}: let
  browser = "helium.desktop";
  # browser = "zen-beta.desktop";
in {
  myHomeManager.pipewire-noise-cancling-input.enable = true;
  myHomeManager.distrobox.enable = lib.mkDefault true;

  home.packages = with pkgs; [
    nemo-with-extensions # file manager
    mpv # media player
    imv # image viewer
    zathura # pdf viewer
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = ["zathura.desktop"];

      "inode/directory" = ["nemo.desktop"];

      "image/*" = ["imv.desktop"];

      "video/png" = ["mpv.desktop"];
      "video/jpg" = ["mpv.desktop"];
      "video/*" = ["mpv.desktop"];

      "x-scheme-handler/discord" = ["vesktop.desktop"];

      "application/x-extension-htm" = browser;
      "application/x-extension-html" = browser;
      "application/x-extension-shtml" = browser;
      "application/x-extension-xht" = browser;
      "application/x-extension-xhtml" = browser;
      "application/xhtml+xml" = browser;
      "text/html" = browser;
      "x-scheme-handler/chrome" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = [browser];
      "x-scheme-handler/unknown" = browser;
    };
  };
}
