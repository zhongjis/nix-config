{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./lsp.nix
    ./formatters.nix
    ./permission.nix
    ./provider.nix
  ];
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
    };
  };
}
