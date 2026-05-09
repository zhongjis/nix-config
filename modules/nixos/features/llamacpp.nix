{
  lib,
  pkgs,
  ...
}: let
  llamaCpp = pkgs.llama-cpp-vulkan;
  llamaServer = lib.getExe' llamaCpp "llama-server";
  huggingfaceCli = pkgs.python3Packages.huggingface-hub;

  modelConfig = import ../../../lib/llamacpp-models.nix {inherit lib;};
  inherit (modelConfig) modelFiles modelPath modelsDir hfHome;

  commonFlags = [
    "--host"
    "127.0.0.1"
    "--port"
    "\${PORT}"
    "--no-webui"
    "-ngl"
    "999"
    "-c"
    "32768"
  ];

  mkModel = model:
    {
      cmd = lib.concatStringsSep " " ([
          llamaServer
          "--model"
          (modelPath model)
        ]
        ++ commonFlags
        ++ (model.extraFlags or []));
    }
    // lib.optionalAttrs (model.unlisted or false) {unlisted = true;};
in {
  environment.systemPackages = [
    llamaCpp
    huggingfaceCli
  ];

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
    "d ${hfHome} 0700 root root -"
  ];

  services.llama-swap = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9292;

    settings = {
      healthCheckTimeout = 120;
      startPort = 5801;

      models = lib.mapAttrs (_: mkModel) modelFiles;
    };
  };
}
