{
  lib,
  aiProfileHelpers,
  ...
}: let
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
  programs.mcp = {
    enable = true;
    servers =
      commonMcps
      // lib.optionalAttrs aiProfileHelpers.isWork workMcps
      // lib.optionalAttrs aiProfileHelpers.isPersonal personalMcps;
  };
}
