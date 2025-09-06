{...}: {
  # NOTE: disable for determinate nix
  # https://github.com/DeterminateSystems/determinate
  nix.enable = false;
  nix.optimise.automatic = false;
  nix.gc.automatic = false;
}
