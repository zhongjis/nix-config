{
  inputs,
  pkgs,
  currentSystemUser,
  ...
}: let
  unstable_pkgs = with pkgs.unstable; [
    # placeholder
  ];
in {
  myNixDarwin = {
    bundles.general-desktop.enable = true;
    bundles.work.enable = true;
  };

  users.users.${currentSystemUser} = {
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [] ++ unstable_pkgs;

  services.nix-daemon.enable = true;

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
