return {
  "mbbill/undotree",

  config = function()
    vim.keymap.set(
      "n",
      "<leader>u",
      vim.cmd.UndotreeToggle,
      { desc = "[U]ndotree Toggle", noremap = true }
    )
  end,
}
