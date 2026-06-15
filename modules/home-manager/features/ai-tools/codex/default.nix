{
  inputs,
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
in {
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    impeccable.enable = true;
    caveman = {
      enable = true;
      mode = "ultra";
    };
    package = llmAgentsPackages.codex;
    context = codexContext;
    rules = {};
    settings = {
      approval_policy = "never";
      allow_login_shell = true;
      sandbox_mode = "workspace-write";

      shell_environment_policy = {
        "inherit" = "all";
        experimental_use_profile = true;
      };
    };
    skills = commonSkills;
  };
}
