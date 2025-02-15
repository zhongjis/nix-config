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
  boot.kernelPackages = pkgs.linuxPackages_latest;

  myNixOS = {
    bundles.general-desktop.enable = true;
    bundles.hyprland.enable = true;
    bundles.gaming.enable = true;
    services.amdcpu.enable = true;
    services.amdgpu.enable = true;
    multi-lang-input-layout.enable = true;
    podman.enable = true;
    ollama.enable = true;
    open-webui.enable = true;
    sops.enable = true;
  };

  # for radeon 7700s
  services.ollama = {
    package = pkgs.stable.ollama;
    acceleration = "rocm";
    rocmOverrideGfx = "11.0.2"; # NOTE: failing build on unstalbe as of 01.27.2024
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
  networking.firewall.enable = true;

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

  environment.systemPackages = with pkgs; [
    vivaldi
    neovim
    unzip
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
