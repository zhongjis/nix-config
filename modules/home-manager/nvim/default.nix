{ pkgs, ... }:

{
  programs.neovim = 
  let
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  in
  {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
        ripgrep
        nodejs_21
        unzip
        cargo
    ];

    plugins = with pkgs.vimPlugins; [
      # {
      #   plugin = comment-nvim;
      #   config = toLua "require(\"Comment\").setup()";
      # }

      # {
      #   plugin = nvim-lspconfig;
      #   config = toLuaFile ./nvim/plugin/lsp.lua;
      # }
    ];

    extraLuaConfig = ''
      ${builtins.readFile ./config/options.lua}
      ${builtins.readFile ./config/keymaps.lua}
      ${builtins.readFile ./config/autocmds.lua}
      ${builtins.readFile ./kickstart.lua}
    '';
  };

  home.packages = with pkgs; [
      lazygit
  ];
}
