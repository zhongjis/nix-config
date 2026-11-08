{
  pkgs,
  # inputs,
  lib,
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

  boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  myNixOS = {
    bundles.general-desktop.enable = true;
    plymouth.enable = lib.mkForce false;
    bundles.developer.enable = true;
    bundles.hyprland.enable = true;
    bundles.kde.enable = false;
    bundles.gaming.enable = true;
    bundles."3d-printing".enable = true;
    services.amdcpu.enable = true;
    services.amdgpu.enable = true;
    multi-lang-input-layout.enable = true;
    llamacpp.enable = true;
    sops.enable = true;
    virt-manager.enable = true;
  };

  # xremap
  hardware.uinput.enable = true;
  users.groups = {
    uinput.members = ["zshen"];
    input.members = ["zshen"];
  };

  # Bootloader.
  boot.loader = {
    timeout = 5;
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
  # Agent workloads compress ~3.8x in zram; a RAM-sized device keeps them off
  # disk swap, which stays as lower-priority overflow.
  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };
  boot.kernel.sysctl = {
    # zram swap is cheaper than dropping page cache; kernel allows up to 200.
    "vm.swappiness" = 180;
    # zram has no seek cost, so swap readahead only wastes work.
    "vm.page-cluster" = 0;
  };

  # Cap local builds so a rebuild cannot saturate all 16 threads alongside agents.
  nix.settings = {
    max-jobs = 2;
    cores = 4;
  };
  # batch, not idle: idle builds would starve under constant agent load.
  nix.daemonCPUSchedPolicy = "batch";

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
