{
  inputs,
  pkgs,
  currentSystemUser,
  ...
}: {
  imports = [
    ../../modules/shared
    ../../modules/darwin
  ];

  myNixDarwin = {
    bundles.general.enable = true;
    bundles.work.enable = true;
  };

  users.users.${currentSystemUser} = {
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [];

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
