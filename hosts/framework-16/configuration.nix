{
  pkgs,
  inputs,
  currentSystem,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    inputs.nix-gaming.nixosModules.platformOptimizations
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
  ];

  # gaming kernel. not sure if it is good
  boot.kernelPackages = pkgs.linuxPackages_zen;

  myNixOS = {
    bundles.general-desktop.enable = true;
    bundles.gnome.enable = true;
    bundles.hyprland.enable = true;
    bundles.gaming.enable = true;
    services.amd.enable = true;
    services.virtualization.enable = true;
    power-management-framework.enable = true;
    multi-lang-input-layout.enable = true;
  };

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
      useOSProber = true;
    };
  };
  boot.plymouth.enable = true;

  # Network
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

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
  services = {
    flatpak.enable = true;
    udisks2.enable = true;
    printing.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Open Razer
  hardware.openrazer.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zshen = {
    isNormalUser = true;
    description = "Jason";
    extraGroups = ["networkmanager" "wheel" "openrazer" "audio" "docker"];
    packages = with pkgs; [
      kdePackages.kate
    ];
    shell = pkgs.zsh;
  };

  hardware.cpu.amd.updateMicrocode = true;

  # Logitech Blutooth Devices
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true; # for solaar to be included

  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${currentSystem}".default
    firefox
    neovim
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
