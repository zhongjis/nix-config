{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    kubectl
    helm
    helmfile
    k9s
  ];
}
