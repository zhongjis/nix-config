{
  config,
  pkgs,
  ...
}: let
  # https://nixos.wiki/wiki/Helm_and_Helmfile
  cust-kubernetes-helm = with pkgs;
    wrapHelm kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-secrets
        helm-diff
        helm-s3
        helm-git
      ];
    };

  cust-helmfile = pkgs.helmfile-wrapped.override {
    inherit (cust-kubernetes-helm) pluginsDir;
  };
in {
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

  environment.systemPackages = with pkgs; [
    kubectl
    kustomize

    cust-kubernetes-helm
    cust-helmfile
  ];
}
