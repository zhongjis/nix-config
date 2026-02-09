{
  config,
  lib,
  inputs,
  aiProfileHelpers,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  secretPath = config.sops.secrets.context7_api_key.path;

  # MCPs available to all profiles
  commonMcps = {
    nixos = {
      command = "nix";
      args = ["run" "github:utensils/mcp-nixos" "--"];
    };
    context7 = {
      url = "https://mcp.context7.com/mcp";
      headers = {
        CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
      };
    };
    mcp_k8s = {
      command = "nix";
      args = ["run" "nixpkgs#mcp-k8s-go"];
    };
  };

  # MCPs only for work profile
  workMcps = {
  };

  # MCPs only for personal profile
  personalMcps = {
    flux_operator_mcp = {
      command = "nix";
      args = ["run" "nixpkgs#fluxcd-operator-mcp" "serve"];
      env = {
        "KUBECONFIG" = "/home/zshen/.kube/config";
      };
    };
  };
in {
  sops.secrets.context7_api_key = {
    inherit sopsFile;
  };

  # Export CONTEXT7_API_KEY directly in zsh initialization
  # Reads the sops secret file at shell startup
  programs.zsh.initContent = lib.mkOrder 100 ''
    if [[ -r "${secretPath}" ]]; then
      export CONTEXT7_API_KEY="$(<"${secretPath}")"
    fi
  '';

  programs.mcp = {
    enable = true;
    servers =
      commonMcps
      // lib.optionalAttrs aiProfileHelpers.isWork workMcps
      // lib.optionalAttrs aiProfileHelpers.isPersonal personalMcps;
  };
}
