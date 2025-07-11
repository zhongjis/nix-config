{pkgs, ...}: {
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
    ts = {
      enable = true;
      extensions.ts-error-translator.enable = true;
      format.type = "prettierd";
    };
    java.enable = true;
    terraform.enable = true;
    yaml.enable = true;
    python.enable = true;

    vim.extraPackages = with pkgs; [
      terraform
    ];
  };
}
