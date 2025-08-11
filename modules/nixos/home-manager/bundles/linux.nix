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

      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "x-scheme-handler/chrome" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/about" = ["zen-beta.desktop"];
      "x-scheme-handler/unknown" = "zen-beta.desktop";
    };
  };
}
