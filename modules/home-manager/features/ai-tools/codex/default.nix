{
  inputs,
  pkgs,
  commonSkills,
  commonInstructions,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
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

  codexSettings = {
    model = "gpt-5.4";
    model_provider = "openai";
    model_reasoning_effort = "high";
    approval_policy = "on-request";
    allow_login_shell = true;
    sandbox_mode = "workspace-write";

    sandbox_workspace_write = {
      writable_roots = [];
      network_access = false;
      exclude_tmpdir_env_var = false;
      exclude_slash_tmp = false;
    };

    shell_environment_policy = {
      "inherit" = "all";
      experimental_use_profile = true;
    };
  };
in {
  home.packages = [
    inputs.self.packages.${system}.oh-my-codex
  ];

  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    # package = llmAgentsPackages.codex;
    context = codexContext;
    rules = {};
    settings = codexSettings;
    skills = commonSkills;
  };
}
