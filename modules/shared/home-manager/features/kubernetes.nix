{
  config,
  pkgs,
  ...
}: {
  programs.zsh.shellAliases.k = "kubectl";
  programs.zsh.shellAliases.kt = "kubectx";
  programs.zsh.shellAliases.kn = "kubens";

  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        refreshRate = 2;
      };
    };
  };

  programs.kubecolor = {
    enable = true;
    enableAlias = true;
    enableZshIntegration = config.programs.zsh.enable;
  };
}
