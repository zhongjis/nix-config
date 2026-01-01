{
  config,
  pkgs,
  ...
}: {
  programs.mcp.servers = {
    "nixos" = {
      command = "nix";
      args = ["run" "github:utensils/mcp-nixos"];
    };
    "mcp_k8s" = {
      command = "nix";
      args = ["run" "nixpkgs#mcp-k8s-go"];
    };
    "flux-operator-mcp" = {
      type = "local";
      command = "nix";
      args = ["run" "nixpkgs#fluxcd-operator-mcp" "serve"];
      environment = {
        "KUBECONFIG" = "/home/zshen/.kube/config";
      };
    };
  };
}
