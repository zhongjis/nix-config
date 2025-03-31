{config, ...}: {
  programs.kubecolor = {
    enable = true;
    enableAlias = true;
    enableZshIntegration = config.programs.zsh.enable;
  };
}
