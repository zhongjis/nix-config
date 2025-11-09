{
  config,
  pkgs,
  ...
}: let
  sopsFile = ../../../../secrets/ai-tokens.yaml;
in {
  imports = [
    ./formatters.nix
    ./lsp.nix
    ./permission.nix
    ./provider.nix
  ];

  sops.secrets = {
    # github - personal
    openai_api_key = {
      inherit sopsFile;
    };
    anthropic_api_key = {
      inherit sopsFile;
    };
    openrouter_api_key = {
      inherit sopsFile;
    };
  };

  programs.mcp.servers = {
    "nixos" = {
      command = "nix";
      args = ["nix" "run" "github:utensils/mcp-nixos"];
    };
    "mcp_k8s" = {
      command = "nix";
      args = ["nix" "run" "nixpkgs#mcp-k8s-go"];
    };
    "flux-operator-mcp" = {
      type = "local";
      enabled = true;
      command = ["nix" "run" "nixpkgs#fluxcd-operator-mcp" "serve"];
      environment = {
        "KUBECONFIG" = "/home/zshen/.kube/config";
      };
    };
  };

  programs.opencode = {
    enable = true;
    # package = pkgs.writeShellScriptBin "opencode" ''
    #   export ANTHROPIC_API_KEY="$(cat ${config.sops.secrets.anthropic_api_key.path})"
    #   export OPENAI_API_KEY="$(cat ${config.sops.secrets.openrouter_api_key.path})"
    #   export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openai_api_key.path})"
    #   exec ${pkgs.opencode}/bin/opencode "$@"
    # '';
    enableMcpIntegration = true;

    settings = {
      autoshare = false;
      autoupdate = false;

      model = "anthropic/claude-sonnet-4-20250514";
    };
  };
}
