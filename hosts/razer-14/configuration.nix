{
  pkgs,
  inputs,
  currentSystem,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  myNixOS = {
    bundles.general-desktop.enable = true;
    bundles.hyprland-wm.enable = true;
    bundles.gaming.enable = true;
    services.nvidia.enable = true;
  };

  # console
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-128n.psf.gz";
    packages = with pkgs; [terminus_font];
    keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
  };

  # xremap
  hardware.uinput.enable = true;
  users.groups = {
    uinput.members = ["zshen"];
    input.members = ["zshen"];
  };

  # Bootloader.
  boot.loader = {
    plymouth.enable = true;
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
    extraGroups = ["networkmanager" "wheel" "openrazer" "audio"];
    packages = with pkgs; [
      kdePackages.kate
    ];
    shell = pkgs.zsh;
  };

  hardware.cpu.amd.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${currentSystem}".specific

    openrazer-daemon
    polychromatic
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
