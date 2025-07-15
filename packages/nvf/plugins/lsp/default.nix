{pkgs, ...}: {
  imports = [
    ./formatter.nix
    ./lint.nix
  ];

  vim.lsp.enable = true;
  vim.lsp.lspkind.enable = true;

  vim.languages = {
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    nix = {
      enable = true;
      lsp.server = "nixd";
    };
    markdown.enable = true;
    bash.enable = true;
    lua = {
      enable = true;
      lsp.lazydev.enable = true;
    };
    java.enable = true;
    terraform.enable = true;
    yaml.enable = true;
    python.enable = true;
    css.enable = true;
    tailwind.enable = true;
    html.enable = true;
    sql.enable = true;
    ts = {
      enable = true;
      extensions.ts-error-translator.enable = true;
      format.type = "prettierd";
    };
  };
}
