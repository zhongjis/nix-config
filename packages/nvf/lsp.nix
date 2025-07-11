{
  vim.lsp.enable = true;
  vim.languages = {
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    lua = {
      enable = true;
      lsp.lazydev.enable = true;
    };
    nix = {
      enable = true;
      lsp.server = "nixd";
    };
    ts.enable = true;
    java.enable = true;
    terraform.enable = true;
    yaml.enable = true;
    python.enable = true;
  };
}
