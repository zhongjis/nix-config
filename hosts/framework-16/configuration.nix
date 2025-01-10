{
  pkgs,
  inputs,
  currentSystem,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./fw-fanctrl.nix
    inputs.nix-gaming.nixosModules.platformOptimizations
    inputs.nix-gaming.nixosModules.pipewireLowLatency
  ];

  # gaming kernel. not sure if it is good
  boot.kernelPackages = pkgs.linuxPackages_zen;

  myNixOS = {
    bundles.general-desktop.enable = true;
    bundles.hyprland.enable = true;
    bundles.gaming.enable = true;
    services.amdcpu.enable = true;
    services.amdgpu.enable = true;
    multi-lang-input-layout.enable = true;
    docker.enable = true;
    ollama.enable = true;
  };

  # for radeon 7700s
  services.ollama = {
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx1102"; # used to be necessary, but doesn't seem to anymore
    };
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
  boot.plymouth.enable = true;

  # Network
  networking.hostName = "zshen-framework"; # Define your hostname.
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
    extraGroups = ["networkmanager" "wheel" "audio" "docker"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # Logitech Blutooth Devices
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true; # for solaar to be included

  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages."${currentSystem}".default
    firefox # in case zen broke
    neovim
  ];

  system.stateVersion = "24.05"; # Did you read the comment?
}
