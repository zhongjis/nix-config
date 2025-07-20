{
  pkgs,
  inputs,
  currentSystem,
  ...
}: {
  imports = [
    ../../modules/shared
    ../../modules/nixos
    ./hardware-configuration.nix
    ./fw-fanctrl.nix

    # disk placeholder
    # inputs.disko.nixosModules.default
    # ./disko.nix
  ];

  # gaming kernel. not sure if it is good
  boot.kernelPackages = pkgs.stable.linuxPackages_zen;

  myNixOS = {
    bundles.general-desktop.enable = true;
    bundles.developer.enable = true;
    bundles.hyprland.enable = true;
    bundles.kde.enable = false;
    bundles.gaming.enable = true;
    bundles."3d-printing".enable = true;
    services.amdcpu.enable = true;
    services.amdgpu.enable = true;
    multi-lang-input-layout.enable = true;
    ollama.enable = true;
    sops.enable = true;
    virt-manager.enable = true;
  };

  # for radeon 7700s
  services.ollama = {
    package = pkgs.stable.ollama;
    acceleration = "rocm";
    rocmOverrideGfx = "11.0.2";
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

  # Network
  networking.hostName = "framework-16"; # Define your hostname.
  networking.networkmanager.enable = true;

  # ZRAM
  zramSwap.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable thunderbolt
  services.hardware.bolt.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zshen = {
    isNormalUser = true;
    description = "Jason";
    extraGroups = ["networkmanager" "wheel" "audio"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # Logitech Blutooth Devices
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true; # for solaar to be included

  environment.systemPackages = with pkgs; [];

  system.stateVersion = "24.05"; # Did you read the comment?
}
