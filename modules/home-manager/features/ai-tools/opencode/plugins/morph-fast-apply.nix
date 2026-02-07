# Morph Fast Apply Plugin Configuration
# https://github.com/JRedeker/opencode-morph-fast-apply
#
# Environment variable MORPH_API_KEY is provided via sops-nix
# Get your API key from: https://morphllm.com/dashboard/api-keys
{
  config,
  lib,
  pkgs,
  hasPlugin,
  inputs,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  morphPkg = inputs.self.packages.${pkgs.system}.opencode-morph-fast-apply;
in
  lib.mkIf (hasPlugin "opencode-morph-fast-apply") {
    sops.secrets = {
      morph_api_key = {
        inherit sopsFile;
      };
    };

    # Add morph instructions to opencode
    programs.opencode.settings = {
      instructions = [
        "${morphPkg}/lib/node_modules/opencode-morph-fast-apply/MORPH_INSTRUCTIONS.md"
      ];
    };

    # Optional: Configure morph settings via environment variables
    # Uncomment and modify as needed
    home.sessionVariables = {
      # Default API URL (usually don't need to change)
      # MORPH_API_URL = "https://api.morphllm.com";

      # Model selection: morph-v3-fast (default), morph-v3-large, or auto
      # MORPH_MODEL = "morph-v3-fast";

      # Timeout in milliseconds (default: 30000)
      # MORPH_TIMEOUT = "30000";
    };

    # API key is set via sops-nix in provider.nix
    # The secret path will be: config.sops.secrets.morph_api_key.path
    home.sessionVariablesExtra = ''
      export MORPH_API_KEY="$(cat ${config.sops.secrets.morph_api_key.path} 2>/dev/null || echo "")"
    '';
  }
