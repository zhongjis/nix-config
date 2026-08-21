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
  openDesignDaemon = pkgs.open-design-daemon;
  nextDevtoolsMcp = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.next-devtools-mcp;

  # MCPs available to all profiles
  commonMcps = {
    nixos = {
      command = "nix";
      args = ["run" "github:utensils/mcp-nixos/v2.4.0" "--"];
    };
    context7 = {
      url = "https://mcp.context7.com/mcp";
      headers = {
        CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
      };
    };
    shadcn = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = ["--yes" "shadcn@latest" "mcp"];
    };
    open-design = {
      command = "${openDesignDaemon}/bin/od";
      args = [
        "mcp"
        "--daemon-url"
        "http://127.0.0.1:${toString config.services.open-design.port}"
      ];
    };
  };

  # MCPs only for work profile
  workMcps = {
  };

  # MCPs only for personal profile
  personalMcps = {
    linear = {
      url = "https://mcp.linear.app/mcp";
      headers.Authorization = "{env:LINEAR_AUTHORIZATION}";
    };
    next-devtools = {
      command = "${nextDevtoolsMcp}/bin/next-devtools-mcp";
    };
    flux = {
      command = "nix";
      args = [
        "run"
        "nixpkgs#fluxcd-operator-mcp"
        "--"
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

  # Export MCP credentials directly in zsh initialization.
  # Reads the sops secret files at shell startup.
  programs.zsh.initContent = lib.mkOrder 100 ''
    if [[ -r "${secretPath_context7}" ]]; then
      export CONTEXT7_API_KEY="$(<"${secretPath_context7}")"
    fi
    ${lib.optionalString aiProfileHelpers.isPersonal ''
      if [[ -r "${secretPath_linear}" ]]; then
        export LINEAR_AUTHORIZATION="Bearer $(<"${secretPath_linear}")"
      fi
    ''}
  '';
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
