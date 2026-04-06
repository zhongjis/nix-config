{
  config,
  lib,
  pkgs,
  inputs ? {},
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  defaultRtkPackage =
    if inputs ? llm-agents
    then inputs.llm-agents.packages.${system}.rtk
    else null;

  opencodeRtkCfg = config.programs.opencode.rtk;
  ompRtkCfg = config.programs."oh-my-pi".rtk;

  # Lazy: only evaluated when opencodeRtkCfg.enable is true.
  rtkPluginSrc = pkgs.fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${defaultRtkPackage.version}";
    hash = "sha256-QkAtxSpMyjbscQgSUWks0aIkWaAYXgY6c9qM3sdPN+0=";
  };
in {
  options.programs.opencode.rtk.enable =
    lib.mkEnableOption "RTK integration for OpenCode";

  options.programs."oh-my-pi".rtk = {
    enable = lib.mkEnableOption "RTK integration for Oh My Pi";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultRtkPackage;
      defaultText = lib.literalExpression "inputs.llm-agents.packages.\${pkgs.stdenv.hostPlatform.system}.rtk";
      description = "RTK runtime package installed when programs.\"oh-my-pi\".rtk.enable is true.";
    };

    extension = lib.mkOption {
      type = lib.types.path;
      default = ./extensions/rtk.ts;
      defaultText = lib.literalExpression "./rtk/extensions/rtk.ts";
      description = "Extension file exposed as ~/.omp/agent/extensions/rtk.ts when programs.\"oh-my-pi\".rtk.enable is true.";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !ompRtkCfg.enable || ompRtkCfg.package != null;
          message = ''
            programs."oh-my-pi".rtk.package must be set when programs."oh-my-pi".rtk.enable is true.
            If you import this module outside this flake, pass the package explicitly or provide inputs.llm-agents.
          '';
        }
      ];
    }
    (lib.mkIf opencodeRtkCfg.enable {
      home.packages = [defaultRtkPackage];
      xdg.configFile."opencode/plugins/rtk.ts".source =
        rtkPluginSrc + "/hooks/opencode/rtk.ts";
    })
    (lib.mkIf ompRtkCfg.enable {
      home.packages = [ompRtkCfg.package];
      programs."oh-my-pi".extensions."rtk.ts" = ompRtkCfg.extension;
    })
  ];
}
