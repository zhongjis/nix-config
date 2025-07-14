{...}: {
  programs.opencode = {
    enable = true;
    settings = {
      theme = "gruvbox";
      model = "anthropic/claude-sonnet-4-20250514";
      autoshare = false;
      autoupdate = true;
      mcp = {
        "nixos" = {
          type = "local";
          enabled = true;
          command = [
            "nix"
            "run"
            "github=utensils/mcp-nixos"
            "--"
          ];
        };
        "mcp_k8s" = {
          type = "local";
          enabled = true;
          command = ["mcp-k8s-go"];
        };
        "flux-operator-mcp" = {
          type = "local";
          enabled = true;
          command = [
            "flux-operator-mcp"
            "serve"
          ];
          environment = {
            "KUBECONFIG" = "/home/zshen/.kube/config";
          };
        };
      };
    };
  };
}
