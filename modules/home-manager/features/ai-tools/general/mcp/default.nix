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
        args = ["run" "github:utensils/mcp-nixos" "--"];
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
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
    };
  };
}
