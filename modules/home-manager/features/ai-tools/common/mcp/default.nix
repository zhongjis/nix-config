{
  config,
  lib,
  inputs,
  pkgs,
  aiProfileHelpers,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  secretPath_context7 = config.sops.secrets.context7_api_key.path;
  secretPath_exa = config.sops.secrets.exa_api_key.path;
  secretPath_linear = config.sops.secrets.linear_api_key.path;
  nextDevtoolsMcp = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.next-devtools-mcp;

  # MCPs available to all profiles
  commonMcps = {
    nixos = {
      command = lib.getExe pkgs.mcp-nixos;
    };
    # Credentialed servers read their sops secret at launch, so they work in
    # shells and GUI-launched apps alike without exporting secrets globally.
    context7 = {
      command = lib.getExe (pkgs.writeShellScriptBin "context7-mcp" ''
        CONTEXT7_API_KEY="$(<"${secretPath_context7}")" \
          exec ${lib.getExe pkgs.context7-mcp} "$@"
      '');
    };
    shadcn = {
      command = lib.getExe (pkgs.writeShellScriptBin "shadcn-mcp" ''
        export PATH="${lib.makeBinPath [pkgs.nodejs_24]}''${PATH:+:$PATH}"
        exec ${pkgs.nodejs_24}/bin/npx "$@"
      '');
      args = ["--yes" "shadcn@latest" "mcp"];
    };
  };

  # MCPs only for work profile
  workMcps = {
  };

  # MCPs only for personal profile
  personalMcps = {
    # mcp-proxy sends API_ACCESS_TOKEN as `Authorization: Bearer`.
    linear = {
      command = lib.getExe (pkgs.writeShellScriptBin "linear-mcp" ''
        API_ACCESS_TOKEN="$(<"${secretPath_linear}")" \
          exec ${lib.getExe pkgs.mcp-proxy} --transport streamablehttp "$@"
      '');
      args = ["https://mcp.linear.app/mcp"];
    };
    next-devtools = {
      command = "${nextDevtoolsMcp}/bin/next-devtools-mcp";
    };
    flux = {
      command = lib.getExe pkgs.fluxcd-operator-mcp;
      args = [
        "serve"
        "--read-only"
        "--mask-secrets"
      ];
      env = {
        KUBECONFIG = "/home/zshen/.kube/config";
      };
    };
  };
in {
  sops.secrets.context7_api_key = {
    inherit sopsFile;
  };
  sops.secrets.exa_api_key = {
    inherit sopsFile;
  };
  sops.secrets.linear_api_key = lib.mkIf aiProfileHelpers.isPersonal {
    inherit sopsFile;
  };

  #
  #     if [[ -r "${secretPath_exa}" ]]; then
  #       export EXA_API_KEY="$(<"${secretPath_exa}")"
  #     fi

  programs.mcp = {
    enable = true;
    servers =
      commonMcps
      // lib.optionalAttrs aiProfileHelpers.isWork workMcps
      // lib.optionalAttrs aiProfileHelpers.isPersonal personalMcps;
  };
}
