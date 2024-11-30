{pkgs, ...}: {
  myNixOS.nh.enable = true;
  myNixOS.power-management.enable = true;
  myNixOS.cachix.enable = true;
  myNixOS.stylix.enable = true;

  # for zsh auto completion
  environment.pathsToLink = ["/share/zsh"];

  # console
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-128n.psf.gz";
    packages = with pkgs; [terminus_font];
    keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
  };

  # Time Zone
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sk_SK.UTF-8";
    LC_IDENTIFICATION = "sk_SK.UTF-8";
    LC_MEASUREMENT = "sk_SK.UTF-8";
    LC_MONETARY = "sk_SK.UTF-8";
    LC_NAME = "sk_SK.UTF-8";
    LC_NUMERIC = "sk_SK.UTF-8";
    LC_PAPER = "sk_SK.UTF-8";
    LC_TELEPHONE = "sk_SK.UTF-8";
    LC_TIME = "sk_SK.UTF-8";
  };

  # cooler
  programs.coolercontrol.enable = true;
  programs.coolercontrol.nvidiaSupport = true;

  # enable sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    unzip
    zip
    wget
    git

    neovim

    obsidian
    spotify
    bitwarden
  ];

  fonts.packages = with pkgs; [
    # fonts
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "Iosevka"
        "FiraCode"
        "DroidSansMono"
        "Agave"
      ];
    })
    font-awesome
    sketchybar-app-font
    cm_unicode
    corefonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    inter
    font-awesome
  ];

  # battery
  services.upower.enable = true;

  security.polkit.enable = true;

  hardware = {
    enableAllFirmware = true;
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };
  services.blueman.enable = true;

  programs.dconf.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
    pkgs.xdg-desktop-portal-hyprland
  ];

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
