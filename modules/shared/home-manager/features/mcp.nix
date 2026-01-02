{
  config,
  pkgs,
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
  programs.mcp = {
    enable = true;
    servers = {
      "nixos" = {
        command = "nix";
        args = ["run" "github:utensils/mcp-nixos"];
      };
      "mcp_k8s" = {
        command = "nix";
        args = ["run" "nixpkgs#mcp-k8s-go"];
      };
      "flux-operator-mcp" = {
        command = "nix";
        args = ["run" "nixpkgs#fluxcd-operator-mcp" "serve"];
        environment = {
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
  };
}
