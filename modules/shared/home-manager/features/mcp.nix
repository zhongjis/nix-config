{
  config,
  pkgs,
  ...
}: {
  programs.mcp = {
    enable = true;
    servers = {
      nixos = {
        command = "nix";
        args = ["run" "github:utensils/mcp-nixos"];
      };
      mcp_k8s = {
        command = "nix";
        args = ["run" "nixpkgs#mcp-k8s-go"];
      };
      flux_operator_mcp = {
        command = "nix";
        args = ["run" "nixpkgs#fluxcd-operator-mcp" "serve"];
        env = {
          "KUBECONFIG" = "/home/zshen/.kube/config";
        };
      };
    };
  };
}
