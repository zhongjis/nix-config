{
  lib,
  pkgs,
  config,
  ...
}: {
  sops.secrets = {
    # github - personal
    n8n_api_key = {
      sopsFile = ../../../../../secrets/homelab.yaml;
    };
    github_com_zhongjis_mcp = {
      sopsFile = ../../../../../secrets/access-tokens.yaml;
    };
  };

  home.packages = [pkgs.nodejs];
  programs.claude-code.mcpServers = {
    github = {
      type = "stdio";
      command = "docker";
      args = [
        "run"
        "-i"
        "--rm"
        "-e"
        "GITHUB_PERSONAL_ACCESS_TOKEN"
        "-e"
        "GITHUB_HOST"
        "ghcr.io/github/github-mcp-server"
      ];
      env = {
        GITHUB_HOST = "https://github.com";
        GITHUB_PERSONAL_ACCESS_TOKEN = "$(cat ${config.sops.secrets.github_com_zhongjis_mcp.path})";
      };
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
      type = "stdio";
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
    mcp_n8n = {
      type = "stdio";
      command = "docker";
      args = [
        "run"
        "-i"
        "--rm"
        "--init"
        "-e"
        "MCP_MODE=stdio"
        "-e"
        "LOG_LEVEL=error"
        "-e"
        "DISABLE_CONSOLE_OUTPUT=true"
        "-e"
        "N8N_API_URL"
        "-e"
        "N8N_API_KEY"
        "ghcr.io/czlonkowski/n8n-mcp:latest"
      ];
      env = {
        N8N_API_URL = "https://n8n.zshen.me";
        N8N_API_KEY = "$(cat ${config.sops.secrets.n8n_api_key.path})";
      };
    };
  };
}
