{
  config,
  pkgs,
  ...
}: let
  sopsFile = ../../../../secrets/ai-tokens.yaml;
in {
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

  programs.opencode = {
    enable = true;
    package = pkgs.writeShellScriptBin "opencode" ''
      export ANTHROPIC_API_KEY="$(cat ${config.sops.secrets.anthropic_api_key.path})"
      export OPENAI_API_KEY="$(cat ${config.sops.secrets.openrouter_api_key.path})"
      export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openai_api_key.path})"
      exec ${pkgs.opencode}/bin/opencode "$@"
    '';

    settings = {
      "$schema" = "https://opencode.ai/config.json";
      theme = "gruvbox";
      autoshare = false;
      autoupdate = true;
      mcp = {
        "nixos" = {
          type = "local";
          enabled = true;
          command = [
            "nix"
            "run"
            "github:utensils/mcp-nixos"
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
