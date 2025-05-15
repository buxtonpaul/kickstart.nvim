return { -- Autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local ignore_filetypes = { 'lua' }
      if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
        return { timeout_ms = 500, lsp_fallback = true }
      end
      local lines = vim.fn.system('git diff --unified=0 ' .. vim.fn.bufname(bufnr)):gmatch '[^\n\r]+'
      local ranges = {}
      for line in lines do
        if line:find '^@@' then
          local line_nums = line:match '%+.- '
          if line_nums:find ',' then
            local _, _, first, second = line_nums:find '(%d+),(%d+)'
            table.insert(ranges, {
              start = { tonumber(first), 0 },
              ['end'] = { tonumber(first) + tonumber(second), 0 },
            })
          else
            local first = tonumber(line_nums:match '%d+')
            table.insert(ranges, {
              start = { first, 0 },
              ['end'] = { first + 1, 0 },
            })
          end
        end
      end
      local format = require('conform').format
      for _, range in pairs(ranges) do
        format { range = range }
      end
    end,
    -- format_on_save = function(bufnr)
    --   -- Disable "format_on_save lsp_fallback" for languages that don't
    --   -- have a well standardized coding style. You can add additional
    --   -- languages here or re-enable it for the disabled ones.
    --   local disable_filetypes = { c = true, cpp = true }
    --   if disable_filetypes[vim.bo[bufnr].filetype] then
    --     return nil
    --   else
    --     return {
    --       timeout_ms = 500,
    --       lsp_format = 'fallback',
    --     }
    --   end
    -- end,
    formatters_by_ft = {
      lua = { 'stylua' },
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
    formatters = {
      clang_format = {
        prepend_args = { '--style=file', '--fallback-style=LLVM' },
      },
    },
  },
}
