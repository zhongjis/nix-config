{pkgs, ...}: let
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
  environment.systemPackages = with pkgs; [
    freelens-bin
    fluxcd

    kubectl
    kustomize
    kubectx
    yq # format output formatting

    cust-kubernetes-helm
    cust-helmfile
  ];

  # services.flatpak = {
  #   packages = [
  #     "app.freelens.Freelens"
  #   ];
  # };
}
