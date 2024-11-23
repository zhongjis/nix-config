{
  pkgs,
  inputs,
  currentSystem,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./nvidia.nix
  ];

  myNixOS = {
    bundles.general-desktop.enable = true;
    hyprland.enable = true;
    sddm.enable = true;
    power-management.enable = true;
    nh.enable = true;
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
      catppuccin.enable = true;
      catppuccin.flavor = "mocha";
    };
  };

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
    hardware.openrgb.enable = true;
    flatpak.enable = true;
    udisks2.enable = true;
    printing.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zshen = {
    isNormalUser = true;
    description = "Jason";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [
      kdePackages.kate
    ];
    shell = pkgs.zsh;
  };

  # better power consumption
  # services.thermald.enable = true;
  # services.tlp.enable = true;
  # services.power-profiles-daemon.enable = true;

  hardware.cpu.amd.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    neovim
    git
    polychromatic
    firefox
    inputs.zen-browser.packages."${currentSystem}".specific
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
