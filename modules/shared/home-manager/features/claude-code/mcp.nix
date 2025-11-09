{
  lib,
  pkgs,
  ...
}: {
  programs.claude-code.mcpServers = {
    github = {
      type = "stdio";
      command = lib.getExe pkgs.github-mcp-server;
      args = [
        # NOTE: avoid accidentally causing unexpected changes with default MCP and whitelist allow
        "--read-only"
        "stdio"
      ];
    };
    nixos = {
      type = "stdio";
      command = "nix";
      args = ["run" "github:utensils/mcp-nixos"];
    };
    mcp_k8s = {
      type = "stdio";
      command = "nix";
      args = ["run" "nixpkgs#mcp-k8s-go"];
    };
    flux-operator-mcp = {
      command = "nix";
      args = ["run" "nixpkgs#fluxcd-operator-mcp" "serve"];
      env = {
        "KUBECONFIG" = "/home/zshen/.kube/config";
      };
    };
    socket = {
      type = "http";
      url = "https://mcp.socket.dev/";
    };
  };
}
