{
  inputs,
  pkgs,
  lib,
  ...
}: {
  myNixOS.nh.enable = lib.mkDefault true;
  myNixOS.sops.enable = lib.mkDefault true;
  myNixOS.power-management.enable = lib.mkDefault true;
  myNixOS.stylix.enable = lib.mkDefault true;
  myNixOS.plymouth.enable = lib.mkDefault true;
  myNixOS.flatpak.enable = lib.mkDefault true;
  myNixOS.xremap.enable = lib.mkDefault true;

  # firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [111 2049];

  # fwupd - firmware update
  services.fwupd.enable = lib.mkDefault true;

  # Enable CUPS to print documents.
  services.printing.enable = lib.mkDefault true;

  # Enable USB auto mounting
  services = {
    udisks2.enable = lib.mkDefault true;
    gvfs.enable = lib.mkDefault true;
  };

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
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

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

  environment.systemPackages = with pkgs;
    [
      unzip
      zip
      wget
      git
      bind
      nfs-utils

      neovim

      obsidian
      bitwarden-desktop
      fluent-reader

      vivaldi
      ghostty
    ]
    ++ [
      # inputs.zen-browser.packages.${pkgs.system}.default
    ];

  fonts.packages = with pkgs; [
    # fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.agave
    font-awesome
    sketchybar-app-font
    cm_unicode
    corefonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    inter
    font-awesome
  ];

  # battery
  services.upower.enable = true;

  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (
          subject.isInGroup("users")
            && (
              action.id == "org.freedesktop.login1.reboot" ||
              action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
              action.id == "org.freedesktop.login1.power-off" ||
              action.id == "org.freedesktop.login1.power-off-multiple-sessions"
            )
          )
        {
          return polkit.Result.YES;
        }
      })
    '';
  };

  hardware.enableAllFirmware = lib.mkDefault true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
