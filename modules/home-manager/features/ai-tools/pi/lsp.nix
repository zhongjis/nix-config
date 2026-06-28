{commonLsp, ...}: {
  home.file.".pi/agent/lsp.json".text = builtins.toJSON {
    lsp = commonLsp;
  };
}
