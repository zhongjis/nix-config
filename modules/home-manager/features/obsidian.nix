{...}: {
  # NOTE: package managed outside Home Manager (NixOS system packages / Homebrew cask)
  programs.obsidian = {
    enable = true;
    package = null;
    cli.enable = true;
  };
}
