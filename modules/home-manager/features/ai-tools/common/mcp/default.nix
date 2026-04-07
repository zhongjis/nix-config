{
  config,
  lib,
  inputs,
  aiProfileHelpers,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  secretPath_context7 = config.sops.secrets.context7_api_key.path;
  secretPath_exa = config.sops.secrets.exa_api_key.path;

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
  };

  # MCPs only for work profile
  workMcps = {
  };

  # MCPs only for personal profile
  personalMcps = {
    # mcp_k8s = {
    #   command = "nix";
    #   args = ["run" "nixpkgs#mcp-k8s-go"];
    # };
    # flux_operator_mcp = {
    #   command = "nix";
    #   args = ["run" "nixpkgs#fluxcd-operator-mcp" "serve"];
    #   env = {
    #     "KUBECONFIG" = "/home/zshen/.kube/config";
    #   };
    # };
  };
in {
  sops.secrets.context7_api_key = {
    inherit sopsFile;
  };

  # Export CONTEXT7_API_KEY directly in zsh initialization
  # Reads the sops secret file at shell startup
  programs.zsh.initContent = lib.mkOrder 100 ''
    if [[ -r "${secretPath_context7}" ]]; then
      export CONTEXT7_API_KEY="$(<"${secretPath_context7}")"
    fi

    if [[ -r "${secretPath_exa}" ]]; then
      export EXA_API_KEY="$(<"${secretPath_exa}")"
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
