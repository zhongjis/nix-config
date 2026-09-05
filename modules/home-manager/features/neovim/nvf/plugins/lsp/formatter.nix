{pkgs, ...}: {
  vim.extraPackages = with pkgs; [
    stylua
    nixpkgs-fmt
    alejandra
    shfmt
    prettierd
    black
    google-java-format
    xmlstarlet
    scalafmt
  ];

  vim.languages.enableFormat = true;
  vim.lsp.formatOnSave = true;
  vim.lsp.mappings.format = null;
  vim.formatter.conform-nvim = {
    enable = true;
    setupOpts = {
      formatters = {
        stylua = {
          prepend_args = [
            "--indent-type"
            "Spaces"
            "--indent-width"
            "2"
            "--column-width"
            "85"
            "--sort-requires"
          ];
        };
        shfmt = {
          args = [
            "-i"
            "2"
            "-ci"
          ];
        };
      };
      formatters_by_ft = {
        lua = ["stylua"];
        nix = ["alejandra"];
        sh = ["shfmt"];
        javascript = ["prettierd"];
        typescript = ["prettierd"];
        typescriptreact = ["prettierd"];
        javascriptreact = ["prettierd"];
        yaml = ["prettierd"];
        markdown = ["prettierd"];
        python = ["black"];
        css = ["prettierd"];
        scss = ["prettierd"];
        terraform = ["terraform_fmt"];
        java = ["google-java-format"];
        scala = ["scalafmt"];
        sbt = ["scalafmt"];
        xml = ["xmlstarlet"];
        json = ["prettierd"];
        jsonc = ["prettierd"];
        html = ["prettierd"];
        graphql = ["prettierd"];
      };
      format_after_save = null;
    };
  };
}
