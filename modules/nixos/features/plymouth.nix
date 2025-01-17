{pkgs, ...}: {
  boot.plymouth = {
    enable = true;
    theme = "catppuccin-mocha";
    themePackages = with pkgs; [
      (catppuccin-plymouth.override {
        variant = "mocha";
      })
    ];
  };

  # Enable "Silent Boot"
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];
  # Hide the OS choice for bootloaders.
  # It's still possible to open the bootloader list by pressing any key
  # It will just not appear on screen unless a key is pressed
  boot.loader.timeout = 0;
}
