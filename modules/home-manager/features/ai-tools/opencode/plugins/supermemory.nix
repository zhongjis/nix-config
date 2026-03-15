# Supermemory Plugin Configuration
# https://github.com/supermemoryai/opencode-supermemory
#
# Environment variable SUPERMEMORY_API_KEY is provided via sops-nix
{
  config,
  lib,
  hasPlugin,
  inputs,
  ...
}: let
  sopsFile = inputs.self + "/secrets/ai-tokens.yaml";
  secretPath = config.sops.secrets.supermemory_api_key.path;
in
  lib.mkIf (hasPlugin "opencode-supermemory") {
    sops.secrets.supermemory_api_key = {
      inherit sopsFile;
    };

    # Export SUPERMEMORY_API_KEY directly in zsh initialization
    # Reads the sops secret file at shell startup
    programs.zsh.initContent = lib.mkOrder 100 ''
      if [[ -r "${secretPath}" ]]; then
        export SUPERMEMORY_API_KEY="$(<"${secretPath}")"
      fi
    '';

    # When oh-my-opencode is also active, disable its built-in context compaction
    # hook since supermemory handles compaction itself (preemptive at 80% capacity)
    programs.opencode.ohMyOpenCode.settings = lib.mkIf (hasPlugin "oh-my-opencode") {
      disabled_hooks = ["anthropic-context-window-limit-recovery"];
    };
  }
