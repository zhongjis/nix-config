{
  inputs,
  config,
  lib,
  pkgs,
  commonInstructions,
  aiProfileHelpers,
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
  selectedSkills = inputs.agent-skills.lib.skillsFor {
    profile = aiProfileHelpers.profile;
    harness = "codex";
  };

  dropNulls = value:
    if builtins.isAttrs value
    then lib.mapAttrs (_: dropNulls) (lib.filterAttrs (_: attrValue: attrValue != null) value)
    else if builtins.isList value
    then map dropNulls (lib.filter (item: item != null) value)
    else value;

  envHeaderVariable = value: let
    match = builtins.match "[{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" value;
  in
    if match != null
    then builtins.elemAt match 0
    else null;

  normalizeMcpServer = server: let
    isUrlServer = (server.url or null) != null;
    enabled =
      if (server.enabled or null) != null
      then server.enabled
      else !(server.disabled or false);
    headers = server.http_headers or server.headers or {};
    staticHeaders = lib.filterAttrs (_: value: envHeaderVariable value == null) headers;
    envHeaders =
      lib.mapAttrs (_: value: envHeaderVariable value)
      (lib.filterAttrs (_: value: envHeaderVariable value != null) headers)
      // (server.env_http_headers or {});
    baseServer = {
      inherit enabled;
    };
  in
    dropNulls (
      if isUrlServer
      then
        baseServer
        // {
          url = server.url;
        }
        // lib.optionalAttrs (staticHeaders != {}) {
          http_headers = staticHeaders;
        }
        // lib.optionalAttrs (envHeaders != {}) {
          env_http_headers = envHeaders;
        }
      else
        baseServer
        // {
          command = server.command;
        }
        // lib.optionalAttrs ((server.args or []) != []) {
          args = server.args;
        }
        // lib.optionalAttrs ((server.env or {}) != {}) {
          env = server.env;
        }
    );

  codexMcpServers = lib.optionalAttrs config.programs.mcp.enable (
    lib.mapAttrs (
      _name: server: normalizeMcpServer server
    )
    config.programs.mcp.servers
  );
  codexSeedSettings =
    {
      approval_policy = "never";
      allow_login_shell = true;
      sandbox_mode = "workspace-write";

      shell_environment_policy = {
        "inherit" = "all";
        experimental_use_profile = true;
      };
    }
    // lib.optionalAttrs (codexMcpServers != {}) {
      mcp_servers = codexMcpServers;
    };
in {
  programs.codex = {
    enable = true;
    seedSettings = codexSeedSettings;
    caveman = {
      enable = true;
      mode = "ultra";
    };
    package = llmAgentsPackages.codex;
    context = codexContext;
    rules = {};
    # Codex mutates ~/.codex/config.toml for project trust and local state.
    # Keep Home Manager from owning the live file; seed defaults via programs.codex.seedSettings.
    settings = {};
    skills = selectedSkills;
  };
}
