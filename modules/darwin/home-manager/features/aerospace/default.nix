{...}: {
  programs.aerospace = {
    enable = true;
    package = null; # managed by darwin homebrew
  };

  home.file.".config/aerospace/aerospace.toml".source = ./aerospace.toml;
}
