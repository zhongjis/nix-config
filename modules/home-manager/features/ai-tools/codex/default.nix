{
  inputs,
  config,
  lib,
  pkgs,
  commonSkills,
  commonInstructions,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  llmAgentsPackages = inputs.llm-agents.packages.${system};
  rtkPackage = llmAgentsPackages.rtk;
  rtkRepo = pkgs.fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${rtkPackage.version}";
    hash = "sha256-QkAtxSpMyjbscQgSUWks0aIkWaAYXgY6c9qM3sdPN+0=";
  };
  codexRtkInstructions = let
    nestedPath = rtkRepo + "/hooks/codex/rtk-awareness.md";
    flatPath = rtkRepo + "/hooks/rtk-awareness-codex.md";
  in
    if builtins.pathExists nestedPath
    then nestedPath
    else flatPath;
  codexContext = builtins.concatStringsSep "\n\n" (
    (map builtins.readFile commonInstructions)
    ++ [(builtins.readFile codexRtkInstructions)]
  );

  trustedPersonalProjects = [
    "nix-config"
    "server-config"
    "ghostline"
  ];
  codexMcpServers = lib.optionalAttrs config.programs.mcp.enable (
    lib.mapAttrs (
      _name: server:
        (lib.removeAttrs server [
          "disabled"
          "headers"
        ])
        // (lib.optionalAttrs (server ? headers && !(server ? http_headers)) {
          http_headers = server.headers;
        })
        // {
          enabled = !(server.disabled or false);
        }
    )
    config.programs.mcp.servers
  );
  codexSettings =
    {
      model = "gpt-5.5";
      model_provider = "openai";
      model_reasoning_effort = "xhigh";
      approval_policy = "never";
      allow_login_shell = true;
      sandbox_mode = "workspace-write";

      sandbox_workspace_write = {
        writable_roots = [];
        network_access = false;
        exclude_tmpdir_env_var = false;
        exclude_slash_tmp = false;
      };

      projects =
        builtins.listToAttrs
        (map (name: {
            name = "${config.home.homeDirectory}/personal/${name}";
            value.trust_level = "trusted";
          })
          trustedPersonalProjects);

      shell_environment_policy = {
        "inherit" = "all";
        experimental_use_profile = true;
      };
    }
    // lib.optionalAttrs (codexMcpServers != {}) {
      mcp_servers = codexMcpServers;
    };
  codexConfigSeed = (pkgs.formats.toml {}).generate "codex-config-seed.toml" codexSettings;
  codexConfigPath = "${config.home.homeDirectory}/.codex/config.toml";
in {
  # home.packages = [
  #   llmAgentsPackages.oh-my-codex
  # ];

  home.activation.seedCodexConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    codex_config=${lib.escapeShellArg codexConfigPath}

    if [ ! -e "$codex_config" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$codex_config")"
      $DRY_RUN_CMD install -m 0600 ${codexConfigSeed} "$codex_config"
    fi
  '';

  programs.codex = {
    enable = true;
    impeccable.enable = true;
    caveman = {
      enable = true;
      mode = "ultra";
    };
    package = llmAgentsPackages.codex;
    context = codexContext;
    rules = {};
    # Codex mutates ~/.codex/config.toml for project trust and other local state.
    # Seed the file once via activation, then leave the live file mutable.
    settings = {};
    skills = commonSkills;
  };
}
