{pkgs, ...}: {
  myHomeManager.pipewire-noise-cancling-input.enable = true;

  home.packages = with pkgs; [
    nemo-with-extensions # file manager
    mpv # media player
    imv # image viewer
    zathura # pdf viewer
    vivaldi # web browser
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

      "application/x-extension-htm" = "vivaldi-stable.desktop";
      "application/x-extension-html" = "vivaldi-stable.desktop";
      "application/x-extension-shtml" = "vivaldi-stable.desktop";
      "application/x-extension-xht" = "vivaldi-stable.desktop";
      "application/x-extension-xhtml" = "vivaldi-stable.desktop";
      "application/xhtml+xml" = "vivaldi-stable.desktop";
      "text/html" = "vivaldi-stable.desktop";
      "x-scheme-handler/chrome" = "vivaldi-stable.desktop";
      "x-scheme-handler/http" = "vivaldi-stable.desktop";
      "x-scheme-handler/https" = "vivaldi-stable.desktop";
      "x-scheme-handler/about" = ["vivaldi-stable.desktop"];
      "x-scheme-handler/unknown" = "vivaldi-stable.desktop";
    };
  };
}
