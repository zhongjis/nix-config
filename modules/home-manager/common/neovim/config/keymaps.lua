local map = function(keys, func, desc)
  vim.keymap.set("n", keys, func, { desc = desc, noremap = true })
end

map("<Esc>", "<cmd>nohlsearch<CR>", "")

-- continuous indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- do not override register when paste*
vim.keymap.set("x", "p", [["_dP]])

-- **trouble.nvim**
map("<leader>q", "<cmd>Trouble qflist toggle<cr>", "Toggle [Q]uickfix List")
map("]q", function()
  if require("trouble").is_open() then
    require("trouble").next({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cnext)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, "Go to next [T]rouble item")
map("[q", function()
  if require("trouble").is_open() then
    require("trouble").prev({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cprev)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, "Go to previous [T]rouble item")
map("<leader>e", vim.diagnostic.open_float, "Show diagnostic [E]rror messages")

-- **file explorer**
-- map("<leader>o", "<CMD>Oil<CR>", "[O]il: Open parent directory")

map("<leader>o", function()
  local filetype = vim.bo.filetype
  if filetype == "netrw" then
    -- Navigate to the parent directory in netrw
    local current_path = vim.fn.expand("%:p")
    local parent_path = vim.fn.fnamemodify(current_path, ":h:h")
    vim.cmd("Explore " .. parent_path)
  else
    -- Open the directory of the current file in netrw
    local file_dir = vim.fn.expand("%:p:h")
    vim.cmd("Explore " .. file_dir)
  end
end, "")

-- **telescope**
local builtin = require("telescope.builtin")
map("<leader>sh", builtin.help_tags, "[S]earch [H]elp")
map("<leader>sf", builtin.find_files, "[S]earch [F]iles")
map("<leader>ss", builtin.builtin, "[S]earch [S]elect Telescope")
map("<leader>sw", builtin.grep_string, "[S]earch current [W]ord")
map("<leader>sg", builtin.live_grep, "[S]earch by [G]rep")
map("<leader>sr", builtin.resume, "[S]earch [R]esume")
map(
  "<leader>/",
  builtin.current_buffer_fuzzy_find,
  "[/] Fuzzily search in current buffer"
)
map("<leader>s/", function()
  builtin.live_grep({
    grep_open_files = true,
    prompt_title = "Live Grep in Open Files",
  })
end, "[S]earch [/] in Open Files")

-- **harpoon**
local harpoon = require("harpoon")
map("<leader>a", function()
  harpoon:list():add()
end, "Harpoon: [a]dd file to list")
map("<leader>h", function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, "[H]arpoon: quick menu")
map("<c-h>", function()
  harpoon:list():select(1)
end, "Harpoon: go to file 1")
map("<c-j>", function()
  harpoon:list():select(2)
end, "Harpoon: go to file 2")
map("<c-k>", function()
  harpoon:list():select(3)
end, "Harpoon: go to file 3")
map("<c-l>", function()
  harpoon:list():select(4)
end, "Harpoon: go to file 4")

-- **conform**
map("<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, "[F]ormat buffer")

-- **lazygit.nvim**
map("<leader>gg", "<cmd>LazyGit<CR>", "LazyGit")

-- **undotree**
map("<leader>u", "<cmd>UndotreeToggle<CR>", "[U]ndotree Toggle")

-- **zen-mode.nvim**
map("<leader>zz", function()
  require("zen-mode").toggle({ width = 0.85 })
end, "Toggle [Z]en Mode")
