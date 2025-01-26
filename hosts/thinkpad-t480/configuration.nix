# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./gaming.nix
  ];

  # set global nix path
  nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

  # xremap
  hardware.uinput.enable = true;
  users.groups = {
    uinput.members = ["zshen"];
    input.members = ["zshen"];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = false;

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      devices = ["nodev"];
      efiSupport = true;
      useOSProber = true;
    };
  };

  networking = {
    hostName = "thinkpad-t480"; # Define your hostname.
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
  };

  # Set your time zone.
  services.automatic-timezoned.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-128n.psf.gz";
    packages = with pkgs; [terminus_font];
    keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
  };

  # ZRAM
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true;
  # Enable pipewire for screen sharing sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zshen = {
    isNormalUser = true;
    extraGroups = ["wheel" "input"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      brightnessctl
      obsidian
      font-manager
      kdePackages.dolphin
      evince # pdf viewer
      unzip
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [];

  system.stateVersion = "24.05"; # Did you read the comment?
}
