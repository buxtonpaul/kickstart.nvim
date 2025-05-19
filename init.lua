require 'config.options'
require 'config.keymaps'
require 'config.lazy'

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- still more tidy up to do below

vim.opt.termguicolors = true
require('bufferline').setup {
  options = {
    offsets = {
      {
        filetype = 'NvimTree',
        text = 'File Explorer',
        highlight = 'Directory',
        separator = true, -- use a "true" to enable the default, or set your own character
      },
    },
  },
}
require('overseer').setup {
  strategy = 'toggleterm',
}
vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { desc = 'Toggle File [e]xplorer' })
vim.cmd.colorscheme 'vscode'

-- start ressession
local resession = require 'resession'
require('resession').setup {
  autosave = {
    enabled = true,
    interval = 60,
    notify = true,
  },
  extensions = {
    overseer = {},
  },
}
-- Resession does NOTHING automagically, so we have to set up some keymaps
-- vim.keymap.set("n", "<leader>ss", resession.save)
-- vim.keymap.set("n", "<leader>sl", resession.load)
-- vim.keymap.set("n", "<leader>sd", resession.delete)

-- Setup Lualine
require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = true,
    globalstatus = false,
    refresh = {
      statusline = 100,
      tabline = 100,
      winbar = 100,
    },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { 'filename' },
    lualine_x = { 'overseer', 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = { 'overseer' },
}

-- Setup autocommands, possibly this should be moved to another file and get included....
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    -- Only load the session if nvim was started with no args and without reading from stdin
    if vim.fn.argc(-1) == 0 and not vim.g.using_stdin then
      -- Save these to a different directory, so our manual sessions don't get polluted
      resession.load(vim.fn.getcwd(), { dir = 'dirsession', silence_errors = true })
    end
  end,
  nested = true,
})
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    resession.save(vim.fn.getcwd(), { dir = 'dirsession', notify = false })
  end,
})
vim.api.nvim_create_autocmd('StdinReadPre', {
  callback = function()
    -- Store this for later
    vim.g.using_stdin = true
  end,
})
require('toggleterm').setup {
  direction = 'float',
  open_mapping = [[<c-\>]],
  terminal_mappings = true,
}

--require('quicker').setup()
vim.keymap.set('n', '<leader>q', function()
  require('quicker').toggle()
end, {
  desc = 'Toggle quickfix',
})
vim.keymap.set('n', '<leader>l', function()
  require('quicker').toggle { loclist = true }
end, {
  desc = 'Toggle loclist',
})
require('quicker').setup {
  keys = {
    {
      '>',
      function()
        require('quicker').expand { before = 2, after = 2, add_to_existing = true }
      end,
      desc = 'Expand quickfix context',
    },
    {
      '<',
      function()
        require('quicker').collapse()
      end,
      desc = 'Collapse quickfix context',
    },
  },
}
local harpoon = require 'harpoon'

-- REQUIRED
harpoon:setup()
-- REQUIRED
-- basic telescope configuration
local conf = require('telescope.config').values
local function toggle_telescope(harpoon_files)
  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end

  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Harpoon',
      finder = require('telescope.finders').new_table {
        results = file_paths,
      },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

vim.keymap.set('n', '<leader>ta', function()
  harpoon:list():add()
end, { desc = 'Add buffer to Harpoon list' })
vim.keymap.set('n', '<C-e>', function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = 'Open Harpoon List' })

vim.keymap.set('n', '<C-1>', function()
  harpoon:list():select(1)
end)
vim.keymap.set('n', '<C-2>', function()
  harpoon:list():select(2)
end)
vim.keymap.set('n', '<C-3>', function()
  harpoon:list():select(3)
end)
vim.keymap.set('n', '<C-4>', function()
  harpoon:list():select(4)
end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set('n', '<leader>tp', function()
  harpoon:list():prev()
end, { desc = 'Select Next item in buffer list' })
vim.keymap.set('n', '<leader>tn', function()
  harpoon:list():next()
end, { desc = 'Select Previous item in buffer list' })

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
