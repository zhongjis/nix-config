{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  rtkPkg = inputs.llm-agents.packages.${system}.rtk;

  rtkPluginSrc = pkgs.fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${rtkPkg.version}";
    hash = "sha256-QkAtxSpMyjbscQgSUWks0aIkWaAYXgY6c9qM3sdPN+0=";
  };
in {
  home.packages = [rtkPkg];

  xdg.configFile."opencode/plugins/rtk.ts".source =
    rtkPluginSrc + "/hooks/opencode/rtk.ts";
}
