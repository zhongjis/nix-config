# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../modules/shared
    ../../modules/nixos
    ./hardware-configuration.nix

    # disk
    inputs.disko.nixosModules.default
    ./disko.nix
  ];

  # gaming kernel. not sure if it is good
  boot.kernelPackages = pkgs.linuxPackages_latest;

  myNixOS = {
    bundles.general-desktop.enable = true;
    bundles.hyprland.enable = true;
    bundles.gaming.enable = false;
    multi-lang-input-layout.enable = true;
    docker.enable = false;
    ollama.enable = false; # failing build
  };

  # xremap
  hardware.uinput.enable = true;
  users.groups = {
    uinput.members = ["zshen"];
    input.members = ["zshen"];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = false;

    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      useOSProber = true;
    };
  };

  # Network
  networking = {
    hostName = "thinkpad-t480"; # Define your hostname.
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
  };

  # ZRAM
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zshen = {
    isNormalUser = true;
    extraGroups = ["wheel" "input"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # Select internationalisation properties.
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-128n.psf.gz";
    packages = with pkgs; [terminus_font];
    keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
  };

  environment.systemPackages = with pkgs; [];

  system.stateVersion = "24.05"; # Did you read the comment?
}
