# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules/nixos/hyprland
    ./hardware-configuration.nix
    ../common.nix
    ./gaming.nix
  ];

  # nh
  programs.nh = {
    enable = true;
    package = pkgs.unstable.nh;
    clean.enable = true;
    clean.extraArgs = "--keep-since 30d --keep 10";
    flake = "/home/zshen/personal/nix-config";
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # xremap
  hardware.uinput.enable = true;
  users.groups = {
    uinput.members = ["zshen"];
    input.members = ["zshen"];
  };

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = false;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = false;
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
    };
  };

  # razer
  hardware.openrazer.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  services.automatic-timezoned.enable = true;

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

  # ZRAM
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  # Enable pipewire for screen sharing sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zshen = {
    isNormalUser = true;
    description = "Jason";
    extraGroups = ["networkmanager" "wheel" "openrazer"];
    packages = with pkgs; [
      kdePackages.kate
    ];
    shell = pkgs.zsh;
  };

  # better power consumption
  services.thermald.enable = true;
  # services.tlp.enable = true;
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    git
    openrazer-daemon
    polychromatic
    firefox
    inputs.zen-browser.packages."${system}".specific
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "24.05"; # Did you read the comment?
}
